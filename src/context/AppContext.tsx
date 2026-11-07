import React, { createContext, useContext, useEffect, useMemo, useState } from 'react';
import {
  CuisineCategory,
  Ingredient,
  Recipe,
  RecommendedRecipe,
  UserPreferences,
} from '../types';
import { IngredientNormalizer } from '../utils/ingredientNormalizer';
import { VERIFIED_RECIPES } from '../data/verifiedRecipesData';
import { recommendRecipes } from '../utils/recipeRecommendationEngine';

const STORAGE_KEYS = {
  pantry: 'fridge_chef_pantry_v1',
  seasonings: 'fridge_chef_seasonings_v1',
  preferences: 'fridge_chef_preferences_v1',
  bookmarks: 'fridge_chef_bookmarks_v1',
};

function getRelativeDateIso(daysOffset: number): string {
  const d = new Date();
  d.setDate(d.getDate() + daysOffset);
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

const INITIAL_PANTRY: Ingredient[] = [
  {
    id: 'init_egg',
    name: '계란',
    category: 'eggDairy',
    quantity: 6,
    unit: '개',
    expirationDate: getRelativeDateIso(10),
    confidence: 'high',
    isVerified: true,
  },
  {
    id: 'init_kimchi',
    name: '김치',
    category: 'processed',
    quantity: null,
    unit: null,
    expirationDate: null,
    confidence: 'high',
    isVerified: true,
  },
  {
    id: 'init_green_onion',
    name: '대파',
    category: 'vegetable',
    quantity: 1,
    unit: '대',
    expirationDate: getRelativeDateIso(1),
    confidence: 'high',
    isVerified: true,
  },
  {
    id: 'init_rice',
    name: '밥',
    category: 'grain',
    quantity: 2,
    unit: '공기',
    expirationDate: getRelativeDateIso(2),
    confidence: 'high',
    isVerified: true,
  },
];

const INITIAL_SEASONINGS = [
  '소금',
  '설탕',
  '간장',
  '고추장',
  '고춧가루',
  '된장',
  '식용유',
  '참기름',
  '마늘',
  '후추',
];

interface AppContextType {
  pantryIngredients: Ingredient[];
  ownedSeasonings: Set<string>;
  preferences: UserPreferences;
  selectedCategory: CuisineCategory;
  selectedMainIngredient: string | null;
  bookmarkedRecipeIds: Set<string>;
  allRecipes: Recipe[];
  recommendations: RecommendedRecipe[];
  addOrUpdateIngredient: (ingredient: Ingredient) => void;
  mergeVerifiedScanResults: (items: Ingredient[], replaceExisting?: boolean) => void;
  removeIngredient: (id: string) => void;
  clearPantry: () => void;
  toggleSeasoning: (seasoningName: string) => void;
  selectCategory: (category: CuisineCategory) => void;
  selectMainIngredient: (ingredientName: string | null) => void;
  updatePreferences: (newPreferences: UserPreferences) => void;
  toggleBookmark: (recipeId: string) => void;
}

const AppContext = createContext<AppContextType | null>(null);

export const AppProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [pantryIngredients, setPantryIngredients] = useState<Ingredient[]>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.pantry);
      if (stored) {
        const parsed: Ingredient[] = JSON.parse(stored);
        // Backfill sample expiration dates for untouched initial items if missing
        return parsed.map((item) => {
          if (item.expirationDate === undefined) {
            if (item.id === 'init_green_onion') {
              return { ...item, expirationDate: getRelativeDateIso(1) };
            }
            if (item.id === 'init_rice') {
              return { ...item, expirationDate: getRelativeDateIso(2) };
            }
            if (item.id === 'init_egg') {
              return { ...item, expirationDate: getRelativeDateIso(10) };
            }
          }
          return item;
        });
      }
    } catch (_) {}
    return INITIAL_PANTRY;
  });

  const [ownedSeasonings, setOwnedSeasonings] = useState<Set<string>>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.seasonings);
      if (stored) {
        return new Set(JSON.parse(stored));
      }
    } catch (_) {}
    return new Set(INITIAL_SEASONINGS);
  });

  const [preferences, setPreferences] = useState<UserPreferences>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.preferences);
      if (stored) {
        return JSON.parse(stored);
      }
    } catch (_) {}
    return { allergens: [], dislikedIngredients: [] };
  });

  const [selectedCategory, setSelectedCategory] = useState<CuisineCategory>('all');
  const [selectedMainIngredient, setSelectedMainIngredient] = useState<string | null>(null);

  const [bookmarkedRecipeIds, setBookmarkedRecipeIds] = useState<Set<string>>(() => {
    try {
      const stored = localStorage.getItem(STORAGE_KEYS.bookmarks);
      if (stored) {
        return new Set(JSON.parse(stored));
      }
    } catch (_) {}
    return new Set();
  });

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.pantry, JSON.stringify(pantryIngredients));
    } catch (_) {}
  }, [pantryIngredients]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.seasonings, JSON.stringify(Array.from(ownedSeasonings)));
    } catch (_) {}
  }, [ownedSeasonings]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.preferences, JSON.stringify(preferences));
    } catch (_) {}
  }, [preferences]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.bookmarks, JSON.stringify(Array.from(bookmarkedRecipeIds)));
    } catch (_) {}
  }, [bookmarkedRecipeIds]);

  const addOrUpdateIngredient = (ingredient: Ingredient) => {
    const normalizedName = IngredientNormalizer.normalizeName(ingredient.name);
    if (!normalizedName || IngredientNormalizer.isNonFoodItem(normalizedName)) {
      return;
    }

    const category = IngredientNormalizer.inferCategory(normalizedName, ingredient.category);
    const updatedItem: Ingredient = {
      ...ingredient,
      name: normalizedName,
      category,
      isVerified: true,
    };

    setPantryIngredients((prev) => {
      const idx = prev.findIndex((e) => e.id === updatedItem.id || e.name === updatedItem.name);
      const next = [...prev];
      if (idx >= 0) {
        next[idx] = updatedItem;
      } else {
        next.push(updatedItem);
      }
      return IngredientNormalizer.normalizeAndDeduplicate(next);
    });
  };

  const mergeVerifiedScanResults = (items: Ingredient[], replaceExisting = false) => {
    const cleaned = items.map((e) => ({ ...e, isVerified: true }));
    setPantryIngredients((prev) => {
      const combined = replaceExisting ? cleaned : [...prev, ...cleaned];
      return IngredientNormalizer.normalizeAndDeduplicate(combined);
    });
  };

  const removeIngredient = (id: string) => {
    setPantryIngredients((prev) => {
      const removed = prev.find((e) => e.id === id);
      if (removed && selectedMainIngredient === removed.name) {
        setSelectedMainIngredient(null);
      }
      return prev.filter((e) => e.id !== id);
    });
  };

  const clearPantry = () => {
    setPantryIngredients([]);
    setSelectedMainIngredient(null);
  };

  const toggleSeasoning = (seasoningName: string) => {
    setOwnedSeasonings((prev) => {
      const next = new Set(prev);
      if (next.has(seasoningName)) {
        next.delete(seasoningName);
      } else {
        next.add(seasoningName);
      }
      return next;
    });
  };

  const selectCategory = (category: CuisineCategory) => {
    setSelectedCategory(category);
  };

  const selectMainIngredient = (ingredientName: string | null) => {
    if (!ingredientName || selectedMainIngredient === ingredientName) {
      setSelectedMainIngredient(null);
    } else {
      setSelectedMainIngredient(ingredientName);
    }
  };

  const updatePreferences = (newPreferences: UserPreferences) => {
    setPreferences(newPreferences);
  };

  const toggleBookmark = (recipeId: string) => {
    setBookmarkedRecipeIds((prev) => {
      const next = new Set(prev);
      if (next.has(recipeId)) {
        next.delete(recipeId);
      } else {
        next.add(recipeId);
      }
      return next;
    });
  };

  const allRecipes = VERIFIED_RECIPES;

  const recommendations = useMemo(() => {
    return recommendRecipes({
      pantryIngredients,
      ownedSeasonings,
      preferences,
      allRecipes,
      selectedCategory,
      selectedMainIngredient,
    });
  }, [
    pantryIngredients,
    ownedSeasonings,
    preferences,
    allRecipes,
    selectedCategory,
    selectedMainIngredient,
  ]);

  return (
    <AppContext.Provider
      value={{
        pantryIngredients,
        ownedSeasonings,
        preferences,
        selectedCategory,
        selectedMainIngredient,
        bookmarkedRecipeIds,
        allRecipes,
        recommendations,
        addOrUpdateIngredient,
        mergeVerifiedScanResults,
        removeIngredient,
        clearPantry,
        toggleSeasoning,
        selectCategory,
        selectMainIngredient,
        updatePreferences,
        toggleBookmark,
      }}
    >
      {children}
    </AppContext.Provider>
  );
};

export const useApp = () => {
  const context = useContext(AppContext);
  if (!context) {
    throw new Error('useApp must be used within an AppProvider');
  }
  return context;
};
