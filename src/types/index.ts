export type IngredientCategory =
  | 'vegetable'
  | 'meat'
  | 'seafood'
  | 'eggDairy'
  | 'processed'
  | 'grain'
  | 'seasoning'
  | 'other';

export interface CategoryMeta {
  label: string;
  emoji: string;
}

export const CATEGORY_INFO: Record<IngredientCategory, CategoryMeta> = {
  vegetable: { label: '채소/과일', emoji: '🥬' },
  meat: { label: '육류', emoji: '🥩' },
  seafood: { label: '수산물/해산물', emoji: '🐟' },
  eggDairy: { label: '계란/유제품/두부', emoji: '🥚' },
  processed: { label: '가공식품/햄/면류', emoji: '🥫' },
  grain: { label: '곡류/떡', emoji: '🍚' },
  seasoning: { label: '양념/소스', emoji: '🧂' },
  other: { label: '기타', emoji: '📦' },
};

export type RecognitionConfidence = 'high' | 'medium' | 'low';

export interface Ingredient {
  id: string;
  name: string;
  category: IngredientCategory;
  quantity?: number | null;
  unit?: string | null;
  expirationDate?: string | null; // YYYY-MM-DD
  confidence: RecognitionConfidence;
  uncertaintyNote?: string | null;
  isVerified: boolean;
}

export type ExpirationUrgency = 'expired' | 'expiringSoon' | 'fresh' | 'none';

export interface ExpirationStatusInfo {
  urgency: ExpirationUrgency;
  daysRemaining: number | null;
  label: string | null;
  isWarning: boolean;
}

export function getExpirationStatus(
  expirationDate?: string | null,
  referenceDate: Date = new Date()
): ExpirationStatusInfo {
  if (!expirationDate || !expirationDate.trim()) {
    return { urgency: 'none', daysRemaining: null, label: null, isWarning: false };
  }

  const parts = expirationDate.trim().split('-').map(Number);
  if (parts.length !== 3 || parts.some((n) => Number.isNaN(n))) {
    return { urgency: 'none', daysRemaining: null, label: null, isWarning: false };
  }

  const targetMidnight = new Date(parts[0], parts[1] - 1, parts[2]);
  const refMidnight = new Date(
    referenceDate.getFullYear(),
    referenceDate.getMonth(),
    referenceDate.getDate()
  );

  const diffMs = targetMidnight.getTime() - refMidnight.getTime();
  const daysRemaining = Math.round(diffMs / (1000 * 60 * 60 * 24));

  if (daysRemaining < 0) {
    return {
      urgency: 'expired',
      daysRemaining,
      label: `소비기한 경과 (${Math.abs(daysRemaining)}일 지남)`,
      isWarning: true,
    };
  }

  if (daysRemaining === 0) {
    return {
      urgency: 'expiringSoon',
      daysRemaining: 0,
      label: '소비기한 오늘 만료 (D-Day)',
      isWarning: true,
    };
  }

  if (daysRemaining <= 3) {
    return {
      urgency: 'expiringSoon',
      daysRemaining,
      label: `소비기한 임박 (D-${daysRemaining})`,
      isWarning: true,
    };
  }

  return {
    urgency: 'fresh',
    daysRemaining,
    label: `소비기한 D-${daysRemaining}`,
    isWarning: false,
  };
}

export function formatIngredientQuantity(quantity?: number | null, unit?: string | null): string {
  if (quantity == null || quantity <= 0) {
    return '수량 미지정';
  }
  const formatted = Number.isInteger(quantity)
    ? quantity.toString()
    : quantity.toFixed(1);
  return `${formatted}${unit || '개'}`;
}

export function needsConfirmation(item: Ingredient): boolean {
  return !item.isVerified && (item.confidence === 'medium' || item.confidence === 'low');
}

export type AllergenType =
  | 'egg'
  | 'dairy'
  | 'pork'
  | 'beef'
  | 'chicken'
  | 'shellfish'
  | 'seafood'
  | 'soy'
  | 'wheat';

export interface AllergenMeta {
  type: AllergenType;
  label: string;
  triggerIngredients: string[];
}

export const ALLERGEN_DEFINITIONS: Record<AllergenType, AllergenMeta> = {
  egg: {
    type: 'egg',
    label: '난류(계란)',
    triggerIngredients: ['계란', '달걀', '메추리알', '마요네즈'],
  },
  dairy: {
    type: 'dairy',
    label: '우유/유제품',
    triggerIngredients: ['우유', '치즈', '버터', '생크림', '요거트'],
  },
  pork: {
    type: 'pork',
    label: '돼지고기',
    triggerIngredients: ['돼지고기', '삼겹살', '베이컨', '스팸/통조림햄', '소시지'],
  },
  beef: {
    type: 'beef',
    label: '소고기',
    triggerIngredients: ['소고기', '쇠고기', '우육'],
  },
  chicken: {
    type: 'chicken',
    label: '닭고기',
    triggerIngredients: ['닭고기', '닭가슴살'],
  },
  shellfish: {
    type: 'shellfish',
    label: '갑각류(새우/게)',
    triggerIngredients: ['새우', '게', '새우젓', '굴소스', '피시소스'],
  },
  seafood: {
    type: 'seafood',
    label: '어패류/해산물',
    triggerIngredients: ['고등어', '오징어', '멸치', '어묵', '참치통조림', '조개', '굴', '가쓰오부시'],
  },
  soy: {
    type: 'soy',
    label: '대두(콩/두부)',
    triggerIngredients: ['두부', '콩나물', '된장', '간장'],
  },
  wheat: {
    type: 'wheat',
    label: '밀(면/빵류)',
    triggerIngredients: ['라면', '소면', '파스타면', '우동면', '쌀국수면', '식빵', '부침가루', '밀가루'],
  },
};

export type RecipeDifficulty = 'easy' | 'medium' | 'hard';

export type CuisineCategory =
  | 'all'
  | 'korean'
  | 'western'
  | 'japanese'
  | 'chinese'
  | 'southeastAsian';

export interface CuisineMeta {
  key: CuisineCategory;
  label: string;
  emoji: string;
  primarySourceSite: string;
}

export const CUISINE_DEFINITIONS: Record<CuisineCategory, CuisineMeta> = {
  all: { key: 'all', label: '전체', emoji: '🍽️', primarySourceSite: '전체 플랫폼' },
  korean: { key: 'korean', label: '한식', emoji: '🍚', primarySourceSite: '만개의레시피 (10000recipe)' },
  western: { key: 'western', label: '양식', emoji: '🍝', primarySourceSite: 'BBC Good Food & Allrecipes' },
  japanese: { key: 'japanese', label: '일식', emoji: '🍱', primarySourceSite: 'Cookpad (쿡패드)' },
  chinese: { key: 'chinese', label: '중식', emoji: '🥟', primarySourceSite: '만개의레시피 & 중화요리 표준' },
  southeastAsian: { key: 'southeastAsian', label: '동남아', emoji: '🍜', primarySourceSite: 'Allrecipes & 동남아 현지 레시피' },
};

export interface UserPreferences {
  allergens: AllergenType[];
  dislikedIngredients: string[];
}

export interface NutritionInfo {
  caloriesKcal: number;
  carbsGrams: number;
  proteinGrams: number;
  fatGrams: number;
  sodiumMg: number;
}

export interface RecipeIngredientRequirement {
  name: string;
  baseAmount: number;
  unit: string;
  isSeasoning?: boolean;
  isOptional?: boolean;
  isMainCandidate?: boolean;
  substitutes?: string[];
}

export interface CookingStep {
  stepNumber: number;
  instruction: string;
  tip?: string;
  timerMinutes?: number;
}

export interface Recipe {
  id: string;
  title: string;
  subtitle: string;
  category: string; // '한식', '양식', '일식', '중식', '동남아'
  emoji: string;
  imageUrl: string;
  cookingTimeMinutes: number;
  difficulty: RecipeDifficulty;
  baseServings: number;
  nutritionPerServing: NutritionInfo;
  ingredients: RecipeIngredientRequirement[];
  steps: CookingStep[];
  safetyWarnings?: string[];
  sourceName: string;
  sourceUrl?: string;
}

export type RecommendationTier = 'canMakeNow' | 'almostReady';

export interface RecommendedRecipe {
  recipe: Recipe;
  tier: RecommendationTier;
  matchedIngredients: string[];
  missingCoreIngredients: string[];
  missingSeasonings: string[];
  availableSubstitutes: Record<string, string>;
  pantryUtilizationRatio: number;
  hasUncertainQuantities: boolean;
  usesSelectedMainIngredient: boolean;
  selectedMainIngredientName?: string | null;
  recommendationReason: string;
  utilizationPercentage: number;
}

export interface ScanAnalysisResult {
  recognizedIngredients: Ingredient[];
  excludedNonFoodItems: string[];
  analysisSummary: string;
  isDemoMode: boolean;
  scannedZones: string[];
}
