import '../../preferences/domain/user_preferences.dart';

/// 레시피에 필요한 개별 식재료 항목
class RecipeIngredientRequirement {
  final String name;
  final double baseAmount;
  final String unit;
  final bool isSeasoning;
  final bool isOptional;
  final List<String> substitutes;

  const RecipeIngredientRequirement({
    required this.name,
    required this.baseAmount,
    required this.unit,
    this.isSeasoning = false,
    this.isOptional = false,
    this.substitutes = const [],
  });

  /// 인분 수 변경에 따른 필요 분량 계산 (기본 인분 대비 비례 계산)
  String formatAmountForServings({
    required int baseServings,
    required int targetServings,
  }) {
    if (baseAmount <= 0) return unit;
    final scaled = (baseAmount * targetServings) / baseServings;
    if ((scaled - scaled.roundToDouble()).abs() < 0.05) {
      return '${scaled.round()}$unit';
    }
    // 0.5 단위 표현 정리
    if ((scaled * 2 - (scaled * 2).roundToDouble()).abs() < 0.05) {
      return '${scaled.toStringAsFixed(1)}$unit';
    }
    return '${scaled.toStringAsFixed(1)}$unit';
  }
}

/// 조리 단계
class CookingStep {
  final int stepNumber;
  final String instruction;
  final String? tip;
  final int? timerMinutes;

  const CookingStep({
    required this.stepNumber,
    required this.instruction,
    this.tip,
    this.timerMinutes,
  });
}

/// 레시피 도메인 모델
class Recipe {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String emoji;
  final int cookingTimeMinutes;
  final RecipeDifficulty difficulty;
  final int baseServings;
  final List<RecipeIngredientRequirement> ingredients;
  final List<CookingStep> steps;
  final List<String> safetyWarnings;
  final String sourceName;
  final String? sourceUrl;

  const Recipe({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.emoji,
    required this.cookingTimeMinutes,
    required this.difficulty,
    this.baseServings = 2,
    required this.ingredients,
    required this.steps,
    this.safetyWarnings = const [],
    this.sourceName = '냉장고 셰프 검증 레시피 표준 DB',
    this.sourceUrl,
  });

  List<RecipeIngredientRequirement> get coreIngredients =>
      ingredients.where((i) => !i.isSeasoning && !i.isOptional).toList();

  List<RecipeIngredientRequirement> get seasoningIngredients =>
      ingredients.where((i) => i.isSeasoning).toList();
}

/// 레시피 추천 분류
enum RecommendationTier {
  canMakeNow('지금 만들 수 있는 요리'),
  almostReady('조금만 추가하면 가능한 요리');

  final String label;
  const RecommendationTier(this.label);
}

/// 추천 결과 모델 (규칙 엔진 판정 결과 + 설명 포함)
class RecommendedRecipe {
  final Recipe recipe;
  final RecommendationTier tier;
  final List<String> matchedIngredients;
  final List<String> missingCoreIngredients;
  final List<String> missingSeasonings;
  final Map<String, String> availableSubstitutes;
  final double pantryUtilizationRatio;
  final bool hasUncertainQuantities;
  final String recommendationReason;

  const RecommendedRecipe({
    required this.recipe,
    required this.tier,
    required this.matchedIngredients,
    required this.missingCoreIngredients,
    required this.missingSeasonings,
    this.availableSubstitutes = const {},
    required this.pantryUtilizationRatio,
    required this.hasUncertainQuantities,
    required this.recommendationReason,
  });

  int get utilizationPercentage =>
      (pantryUtilizationRatio * 100).clamp(0, 100).round();
}
