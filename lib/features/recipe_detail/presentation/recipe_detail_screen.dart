import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../../recommendation/domain/recipe.dart';

/// 레시피 상세 화면 (Figma Food Delivery & JavaGem Coffee Shop 레퍼런스 + baseline-ui 적용)
/// - 다크 차콜 캡슐형 인분 스테퍼, 고정폭 숫자(tabularFigures)가 적용된 실시간 칼로리/영양소 계산 카드,
///   필요 재료 체크리스트, 단계별 조리 방법, 식품 안전 주의사항 및 출처 플랫폼 표시
class RecipeDetailScreen extends ConsumerStatefulWidget {
  final RecommendedRecipe recommendedRecipe;

  const RecipeDetailScreen({
    super.key,
    required this.recommendedRecipe,
  });

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  late int _currentServings;

  @override
  void initState() {
    super.initState();
    _currentServings = widget.recommendedRecipe.recipe.baseServings;
  }

  void _changeServings(int delta) {
    final next = (_currentServings + delta).clamp(1, 10);
    setState(() => _currentServings = next);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final recipe = widget.recommendedRecipe.recipe;
    final isBookmarked = appState.bookmarkedRecipeIds.contains(recipe.id);

    final ownedCanonicalNames = {
      ...appState.pantryIngredients
          .map((e) => IngredientNormalizer.normalizeName(e.name)),
      ...appState.ownedSeasonings.map(IngredientNormalizer.normalizeName),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        actions: [
          IconButton(
            key: const Key('bookmark_toggle_button'),
            tooltip: isBookmarked ? '저장 취소' : '레시피 저장',
            onPressed: () {
              ref.read(appStateProvider.notifier).toggleBookmark(recipe.id);
            },
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color:
                  isBookmarked ? AppTheme.terracotta : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(recipe),
          const SizedBox(height: 16),
          _buildNutritionSummaryCard(recipe),
          if (widget.recommendedRecipe.hasUncertainQuantities) ...[
            const SizedBox(height: 12),
            _buildUncertainQuantityNotice(),
          ],
          const SizedBox(height: 16),
          _buildServingsAndIngredientsCard(recipe, ownedCanonicalNames),
          if (recipe.safetyWarnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSafetyWarningsCard(recipe.safetyWarnings),
          ],
          const SizedBox(height: 16),
          _buildCookingStepsSection(recipe),
          const SizedBox(height: 16),
          _buildSourceFooter(recipe),
          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Recipe recipe) {
    final isNow =
        widget.recommendedRecipe.tier == RecommendationTier.canMakeNow;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.terracottaLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    recipe.emoji,
                    style: const TextStyle(fontSize: 34),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isNow
                                  ? AppTheme.primaryGreenLight
                                  : AppTheme.accentAmberLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              widget.recommendedRecipe.tier.label,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: isNow
                                    ? AppTheme.primaryGreenDark
                                    : AppTheme.accentAmberDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.terracottaLight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              recipe.category,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.terracottaDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              recipe.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  Icons.schedule_outlined,
                  '예상 ${recipe.cookingTimeMinutes}분',
                ),
                _buildInfoBadge(
                  Icons.local_fire_department_outlined,
                  '1인분 ${recipe.nutritionPerServing.caloriesKcal}kcal',
                ),
                _buildInfoBadge(
                  Icons.kitchen_outlined,
                  '보유 재료 활용도 ${widget.recommendedRecipe.utilizationPercentage}%',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                '💡 추천 이유: ${widget.recommendedRecipe.recommendationReason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.42,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 칼로리 및 탄수화물·단백질·지방·나트륨 계산 카드 (tabularFigures 적용)
  Widget _buildNutritionSummaryCard(Recipe recipe) {
    final perServing = recipe.nutritionPerServing;
    final totalScaled = perServing.scaleForServings(_currentServings);

    return Card(
      key: const Key('nutrition_summary_card'),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: AppTheme.terracottaDark,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '칼로리 및 영양 성분 계산',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                Text(
                  '$_currentServings인분 기준 (1인분 ${perServing.caloriesKcal}kcal)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _buildMacroTile(
                    label: '총 열량',
                    value: '${totalScaled.caloriesKcal}kcal',
                    highlight: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroTile(
                    label: '탄수화물',
                    value: '${totalScaled.carbsGrams}g',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroTile(
                    label: '단백질',
                    value: '${totalScaled.proteinGrams}g',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMacroTile(
                    label: '지방',
                    value: '${totalScaled.fatGrams}g',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• 예상 나트륨: ${totalScaled.sodiumMg}mg (조리 시 사용하는 양념의 양에 따라 달라질 수 있습니다)',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTheme.textMuted,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTile({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
      decoration: BoxDecoration(
        color: highlight ? AppTheme.terracottaLight : AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlight ? AppTheme.terracotta : AppTheme.borderSubtle,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color:
                  highlight ? AppTheme.terracottaDark : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: AppTheme.tabularFigures,
              color: highlight ? AppTheme.terracottaDark : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppTheme.terracottaDark),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFeatures: AppTheme.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUncertainQuantityNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.accentAmberLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accentAmber),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.accentAmberDark, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '보유 재료 중 정확한 수량이 입력되지 않은 항목이 있습니다. 조리 시작 전 아래의 인분별 필요 분량이 충분한지 확인해 주세요.',
              style: TextStyle(
                fontSize: 12.5,
                color: AppTheme.accentAmberDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Food Delivery 레퍼런스의 다크 차콜 캡슐 스테퍼(- 1인분 +) 및 재료 체크리스트
  Widget _buildServingsAndIngredientsCard(
    Recipe recipe,
    Set<String> ownedCanonicalNames,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '필요한 재료와 분량',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.espressoCharcoal,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('servings_decrease_button'),
                        tooltip: '인분 감소',
                        visualDensity: VisualDensity.compact,
                        color: Colors.white,
                        disabledColor: Colors.white38,
                        onPressed: _currentServings > 1
                            ? () => _changeServings(-1)
                            : null,
                        icon: const Icon(Icons.remove, size: 17),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_currentServings인분',
                          key: const Key('servings_count_text'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('servings_increase_button'),
                        tooltip: '인분 증가',
                        visualDensity: VisualDensity.compact,
                        color: Colors.white,
                        disabledColor: Colors.white38,
                        onPressed: _currentServings < 10
                            ? () => _changeServings(1)
                            : null,
                        icon: const Icon(Icons.add, size: 17),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...recipe.ingredients.map((req) {
              final canonical = IngredientNormalizer.normalizeName(req.name);
              final isOwned = ownedCanonicalNames.contains(canonical);
              final substituteUsed =
                  widget.recommendedRecipe.availableSubstitutes[req.name];
              final formattedAmount = req.formatAmountForServings(
                baseServings: recipe.baseServings,
                targetServings: _currentServings,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isOwned || substituteUsed != null
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 19,
                          color: isOwned || substituteUsed != null
                              ? AppTheme.primaryGreen
                              : AppTheme.accentAmberDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${req.name}${req.isOptional ? ' (선택)' : ''}${req.isSeasoning ? ' [기본양념]' : ''}',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight:
                                  isOwned ? FontWeight.w600 : FontWeight.w700,
                              color: isOwned
                                  ? AppTheme.textPrimary
                                  : AppTheme.accentAmberDark,
                            ),
                          ),
                        ),
                        Text(
                          formattedAmount,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                            fontFeatures: AppTheme.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                    if (req.substitutes.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 27, top: 2),
                        child: Text(
                          substituteUsed != null
                              ? '🔄 보유 중인 [$substituteUsed](으)로 대체 가능합니다.'
                              : '대체 가능 재료: ${req.substitutes.join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSafetyWarningsCard(List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.dangerRedLight.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.dangerRed.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.health_and_safety_outlined,
                color: AppTheme.dangerRed,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                '식품 안전 및 조리 주의사항',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.dangerRed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '• $w',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookingStepsSection(Recipe recipe) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단계별 조리 방법 (초보자 가이드)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            ...recipe.steps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.espressoCharcoal,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.instruction,
                            style: const TextStyle(
                              fontSize: 14.5,
                              height: 1.5,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          if (step.tip != null) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.terracottaLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '💡 초보 팁: ${step.tip}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.terracottaDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceFooter(Recipe recipe) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📚 레시피 출처 기준: ${recipe.sourceName}${recipe.sourceUrl != null ? ' (${recipe.sourceUrl})' : ''}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '• 알레르기 유발 성분은 조리 전 실제 제품의 원재료명을 반드시 직접 확인하세요.',
            style: TextStyle(fontSize: 11.5, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
