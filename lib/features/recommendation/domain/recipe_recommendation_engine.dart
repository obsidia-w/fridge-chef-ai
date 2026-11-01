import '../../../core/utils/ingredient_normalizer.dart';
import '../../pantry/domain/ingredient.dart';
import '../../preferences/domain/user_preferences.dart';
import '../domain/recipe.dart';

/// 식재료 매칭과 조리 가능성 판정을 명확한 규칙으로 수행하는 추천 엔진
/// - 알레르기 및 기피 식재료는 100% 엄격하게 필터링합니다.
/// - 보유 재료 + 보유 기본 양념으로 100% 가능한 요리와 1~2개 부족한 요리를 명확히 분리합니다.
/// - 보유 식재료의 수량이 입력되지 않은 경우 조리 가능 여부 불확실 플래그를 표시합니다.
class RecipeRecommendationEngine {
  const RecipeRecommendationEngine();

  List<RecommendedRecipe> recommend({
    required List<Ingredient> pantryIngredients,
    required Set<String> ownedSeasonings,
    required UserPreferences preferences,
    required List<Recipe> allRecipes,
  }) {
    // 1. 보유 재료 정규화 맵 구성 (이름 -> Ingredient)
    final Map<String, Ingredient> ownedMap = {};
    for (final item in pantryIngredients) {
      final canonical = IngredientNormalizer.normalizeName(item.name);
      ownedMap[canonical] = item;
    }

    final normalizedSeasonings = ownedSeasonings
        .map(IngredientNormalizer.normalizeName)
        .toSet();

    final List<RecommendedRecipe> results = [];

    for (final recipe in allRecipes) {
      // 2. 알레르기 및 기피 식재료 엄격 필터링 (레시피의 모든 재료 검사)
      final hasAllergenOrDisliked = recipe.ingredients.any(
        (req) => preferences.isRestrictedIngredient(req.name),
      );
      if (hasAllergenOrDisliked) {
        continue;
      }

      // 3. 최대 조리 시간 필터링
      if (recipe.cookingTimeMinutes > preferences.maxCookingTimeMinutes) {
        continue;
      }

      // 4. 난이도 필터링 (선호 난이도 이하만 허용)
      if (recipe.difficulty.level > preferences.preferredDifficulty.level) {
        continue;
      }

      final List<String> matched = [];
      final List<String> missingCore = [];
      final List<String> missingSeasonings = [];
      final Map<String, String> substituteUsed = {};
      bool hasUncertainQuantities = false;

      for (final req in recipe.ingredients) {
        final reqCanonical = IngredientNormalizer.normalizeName(req.name);

        if (req.isSeasoning) {
          final hasSeasoning = normalizedSeasonings.contains(reqCanonical) ||
              ownedMap.containsKey(reqCanonical);
          if (hasSeasoning) {
            matched.add(req.name);
          } else {
            // 대체 양념 확인
            String? foundSub;
            for (final sub in req.substitutes) {
              final subCanonical = IngredientNormalizer.normalizeName(sub);
              if (normalizedSeasonings.contains(subCanonical) ||
                  ownedMap.containsKey(subCanonical)) {
                foundSub = sub;
                break;
              }
            }
            if (foundSub != null) {
              matched.add(req.name);
              substituteUsed[req.name] = foundSub;
            } else if (!req.isOptional) {
              missingSeasonings.add(req.name);
            }
          }
          continue;
        }

        // 일반 식재료 매칭
        if (ownedMap.containsKey(reqCanonical)) {
          matched.add(req.name);
          final ownedItem = ownedMap[reqCanonical]!;
          if (!ownedItem.hasExplicitQuantity) {
            hasUncertainQuantities = true;
          }
        } else {
          // 대체 재료 보유 여부 확인
          String? foundSub;
          for (final sub in req.substitutes) {
            final subCanonical = IngredientNormalizer.normalizeName(sub);
            if (ownedMap.containsKey(subCanonical)) {
              foundSub = sub;
              if (!ownedMap[subCanonical]!.hasExplicitQuantity) {
                hasUncertainQuantities = true;
              }
              break;
            }
          }
          if (foundSub != null) {
            matched.add(req.name);
            substituteUsed[req.name] = foundSub;
          } else if (!req.isOptional) {
            missingCore.add(req.name);
          }
        }
      }

      final totalCoreCount = recipe.coreIngredients.length;
      final matchedCoreCount = totalCoreCount - missingCore.length;

      // 최소 1개 이상의 주재료가 매칭되거나 주재료가 2개 이하로 부족한 경우만 추천 후보로 선정
      if (matchedCoreCount == 0 && totalCoreCount > 1) {
        continue;
      }

      final double utilizationRatio = totalCoreCount == 0
          ? 1.0
          : matchedCoreCount / totalCoreCount;

      if (missingCore.isEmpty) {
        results.add(
          RecommendedRecipe(
            recipe: recipe,
            tier: RecommendationTier.canMakeNow,
            matchedIngredients: matched,
            missingCoreIngredients: missingCore,
            missingSeasonings: missingSeasonings,
            availableSubstitutes: substituteUsed,
            pantryUtilizationRatio: utilizationRatio,
            hasUncertainQuantities: hasUncertainQuantities,
            recommendationReason: _buildReason(
              recipe: recipe,
              matched: matched,
              missingCore: missingCore,
              substituteUsed: substituteUsed,
              preferences: preferences,
            ),
          ),
        );
      } else if (missingCore.length <= 2) {
        results.add(
          RecommendedRecipe(
            recipe: recipe,
            tier: RecommendationTier.almostReady,
            matchedIngredients: matched,
            missingCoreIngredients: missingCore,
            missingSeasonings: missingSeasonings,
            availableSubstitutes: substituteUsed,
            pantryUtilizationRatio: utilizationRatio,
            hasUncertainQuantities: hasUncertainQuantities,
            recommendationReason: _buildReason(
              recipe: recipe,
              matched: matched,
              missingCore: missingCore,
              substituteUsed: substituteUsed,
              preferences: preferences,
            ),
          ),
        );
      }
    }

    // 정렬: 1순위 티어(지금 가능 우선), 2순위 활용도 높은 순, 3순위 조리 시간 짧은 순
    results.sort((a, b) {
      if (a.tier != b.tier) {
        return a.tier.index.compareTo(b.tier.index);
      }
      final ratioCmp =
          b.pantryUtilizationRatio.compareTo(a.pantryUtilizationRatio);
      if (ratioCmp != 0) return ratioCmp;
      return a.recipe.cookingTimeMinutes.compareTo(b.recipe.cookingTimeMinutes);
    });

    return results;
  }

  String _buildReason({
    required Recipe recipe,
    required List<String> matched,
    required List<String> missingCore,
    required Map<String, String> substituteUsed,
    required UserPreferences preferences,
  }) {
    final corePreview = matched.take(3).join(', ');
    final subNote = substituteUsed.isNotEmpty
        ? ' (${substituteUsed.entries.map((e) => '${e.key} 대신 ${e.value} 활용').join(', ')})'
        : '';

    if (missingCore.isEmpty) {
      return '보유하신 [$corePreview] 재료로 추가 장보기 없이 ${recipe.cookingTimeMinutes}분 만에 바로 조리할 수 있어요!$subNote';
    } else {
      return '냉장고 속 [$corePreview] 재료를 활용하고, [${missingCore.join(', ')}]만 추가하면 완성할 수 있어요.$subNote';
    }
  }
}
