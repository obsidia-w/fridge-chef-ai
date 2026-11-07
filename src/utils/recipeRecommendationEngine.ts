import {
  CuisineCategory,
  CUISINE_DEFINITIONS,
  Ingredient,
  Recipe,
  RecommendedRecipe,
  UserPreferences,
  ALLERGEN_DEFINITIONS,
} from '../types';
import { IngredientNormalizer } from './ingredientNormalizer';

export function isRestrictedIngredient(
  ingredientName: string,
  preferences: UserPreferences
): boolean {
  const normalized = ingredientName.trim();
  for (const disliked of preferences.dislikedIngredients) {
    const trimmed = disliked.trim();
    if (normalized.includes(trimmed) || trimmed.includes(normalized)) {
      return true;
    }
  }

  for (const allergen of preferences.allergens) {
    const def = ALLERGEN_DEFINITIONS[allergen];
    if (!def) continue;
    for (const trigger of def.triggerIngredients) {
      if (normalized === trigger || normalized.includes(trigger)) {
        return true;
      }
    }
  }

  return false;
}

export function recommendRecipes({
  pantryIngredients,
  ownedSeasonings,
  preferences,
  allRecipes,
  selectedCategory = 'all',
  selectedMainIngredient,
}: {
  pantryIngredients: Ingredient[];
  ownedSeasonings: Set<string>;
  preferences: UserPreferences;
  allRecipes: Recipe[];
  selectedCategory?: CuisineCategory;
  selectedMainIngredient?: string | null;
}): RecommendedRecipe[] {
  // 1. 보유 재료 정규화 맵 구성
  const ownedMap = new Map<string, Ingredient>();
  for (const item of pantryIngredients) {
    const canonical = IngredientNormalizer.normalizeName(item.name);
    ownedMap.set(canonical, item);
  }

  const normalizedSeasonings = new Set<string>();
  for (const s of ownedSeasonings) {
    normalizedSeasonings.add(IngredientNormalizer.normalizeName(s));
  }

  const normalizedMainTarget =
    selectedMainIngredient && selectedMainIngredient.trim()
      ? IngredientNormalizer.normalizeName(selectedMainIngredient)
      : null;

  const results: RecommendedRecipe[] = [];

  for (const recipe of allRecipes) {
    // 2. 요리 카테고리 필터
    if (selectedCategory !== 'all') {
      const expectedLabel = CUISINE_DEFINITIONS[selectedCategory]?.label;
      if (expectedLabel && recipe.category !== expectedLabel) {
        continue;
      }
    }

    // 3. 알레르기 및 기피 식재료 엄격 필터링
    const hasRestricted = recipe.ingredients.some((req) =>
      isRestrictedIngredient(req.name, preferences)
    );
    if (hasRestricted) {
      continue;
    }

    // 4. 메인 재료 필터링
    let usesMainIngredient = false;
    if (normalizedMainTarget) {
      for (const req of recipe.ingredients) {
        if (req.isSeasoning) continue;
        const reqCanonical = IngredientNormalizer.normalizeName(req.name);
        const matchesDirect = reqCanonical === normalizedMainTarget;
        const matchesSubstitute = (req.substitutes || []).some(
          (sub) => IngredientNormalizer.normalizeName(sub) === normalizedMainTarget
        );
        if (matchesDirect || matchesSubstitute) {
          usesMainIngredient = true;
          break;
        }
      }
      if (!usesMainIngredient) {
        continue;
      }
    }

    const matched: string[] = [];
    const missingCore: string[] = [];
    const missingSeasonings: string[] = [];
    const substituteUsed: Record<string, string> = {};
    let hasUncertainQuantities = false;

    for (const req of recipe.ingredients) {
      const reqCanonical = IngredientNormalizer.normalizeName(req.name);

      if (req.isSeasoning) {
        const hasSeasoning =
          normalizedSeasonings.has(reqCanonical) || ownedMap.has(reqCanonical);

        if (hasSeasoning) {
          matched.push(req.name);
        } else {
          let foundSub: string | undefined;
          for (const sub of req.substitutes || []) {
            const subCanonical = IngredientNormalizer.normalizeName(sub);
            if (
              normalizedSeasonings.has(subCanonical) ||
              ownedMap.has(subCanonical)
            ) {
              foundSub = sub;
              break;
            }
          }
          if (foundSub) {
            matched.push(req.name);
            substituteUsed[req.name] = foundSub;
          } else if (!req.isOptional) {
            missingSeasonings.push(req.name);
          }
        }
        continue;
      }

      // 일반 식재료 매칭
      if (ownedMap.has(reqCanonical)) {
        matched.push(req.name);
        const ownedItem = ownedMap.get(reqCanonical)!;
        if (!ownedItem.quantity || ownedItem.quantity <= 0) {
          hasUncertainQuantities = true;
        }
      } else {
        // 대체 재료 확인
        let foundSub: string | undefined;
        for (const sub of req.substitutes || []) {
          const subCanonical = IngredientNormalizer.normalizeName(sub);
          if (ownedMap.has(subCanonical)) {
            foundSub = sub;
            const subItem = ownedMap.get(subCanonical)!;
            if (!subItem.quantity || subItem.quantity <= 0) {
              hasUncertainQuantities = true;
            }
            break;
          }
        }
        if (foundSub) {
          matched.push(req.name);
          substituteUsed[req.name] = foundSub;
        } else if (!req.isOptional) {
          missingCore.push(req.name);
        }
      }
    }

    const coreIngredients = recipe.ingredients.filter(
      (i) => !i.isSeasoning && !i.isOptional
    );
    const totalCoreCount = coreIngredients.length;
    const matchedCoreCount = totalCoreCount - missingCore.length;

    // 최소 1개 이상의 주재료가 매칭되거나 주재료가 2개 이하로 부족한 경우만 추천 후보
    if (matchedCoreCount === 0 && totalCoreCount > 1) {
      continue;
    }

    const utilizationRatio =
      totalCoreCount === 0 ? 1.0 : matchedCoreCount / totalCoreCount;

    if (missingCore.length === 0) {
      results.push({
        recipe,
        tier: 'canMakeNow',
        matchedIngredients: matched,
        missingCoreIngredients: missingCore,
        missingSeasonings,
        availableSubstitutes: substituteUsed,
        pantryUtilizationRatio: utilizationRatio,
        hasUncertainQuantities,
        usesSelectedMainIngredient: usesMainIngredient,
        selectedMainIngredientName: normalizedMainTarget,
        recommendationReason: buildReason({
          matched,
          missingCore,
          substituteUsed,
          mainIngredient: normalizedMainTarget,
        }),
        utilizationPercentage: Math.round(utilizationRatio * 100),
      });
    } else if (missingCore.length <= 2) {
      results.push({
        recipe,
        tier: 'almostReady',
        matchedIngredients: matched,
        missingCoreIngredients: missingCore,
        missingSeasonings,
        availableSubstitutes: substituteUsed,
        pantryUtilizationRatio: utilizationRatio,
        hasUncertainQuantities,
        usesSelectedMainIngredient: usesMainIngredient,
        selectedMainIngredientName: normalizedMainTarget,
        recommendationReason: buildReason({
          matched,
          missingCore,
          substituteUsed,
          mainIngredient: normalizedMainTarget,
        }),
        utilizationPercentage: Math.round(utilizationRatio * 100),
      });
    }
  }

  // 정렬: 1순위 티어(canMakeNow 우선), 2순위 메인 재료 포함 여부, 3순위 활용도 높은 순, 4순위 조리시간 짧은 순
  results.sort((a, b) => {
    if (a.tier !== b.tier) {
      return a.tier === 'canMakeNow' ? -1 : 1;
    }
    if (a.usesSelectedMainIngredient !== b.usesSelectedMainIngredient) {
      return a.usesSelectedMainIngredient ? -1 : 1;
    }
    const ratioCmp = b.pantryUtilizationRatio - a.pantryUtilizationRatio;
    if (Math.abs(ratioCmp) > 0.001) {
      return ratioCmp;
    }
    return a.recipe.cookingTimeMinutes - b.recipe.cookingTimeMinutes;
  });

  return results;
}

function buildReason({
  matched,
  missingCore,
  substituteUsed,
  mainIngredient,
}: {
  matched: string[];
  missingCore: string[];
  substituteUsed: Record<string, string>;
  mainIngredient?: string | null;
}): string {
  const corePreview = matched.slice(0, 3).join(', ');
  const mainPrefix = mainIngredient
    ? `🎯 선택한 메인 재료 [${mainIngredient}] 중심 요리! `
    : '';
  const subEntries = Object.entries(substituteUsed);
  const subNote =
    subEntries.length > 0
      ? ` (${subEntries.map(([k, v]) => `${k} 대신 ${v} 활용`).join(', ')})`
      : '';

  if (missingCore.length === 0) {
    return `${mainPrefix}보유하신 [${corePreview}] 재료로 추가 장보기 없이 바로 조리할 수 있어요!${subNote}`;
  } else {
    return `${mainPrefix}냉장고 속 [${corePreview}] 재료를 활용하고, [${missingCore.join(', ')}]만 추가하면 완성할 수 있어요.${subNote}`;
  }
}
