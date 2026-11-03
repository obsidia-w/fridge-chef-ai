import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../../recommendation/domain/recipe.dart';

/// 레시피 상세 화면 (Figma Food Delivery App by Yamesh_SB & JavaGem Coffee Shop 레퍼런스 직관 반영)
/// - 상단 웜 피치/테라코타 대형 라운드 푸드 쇼케이스 + 플로팅 원형 뒤로가기/북마크 버튼
/// - ⭐ 활용도 · 🔥 1인분 열량 · ⏱ 조리시간 인라인 메타데이터 바
/// - 원형 식재료 아이콘 쇼케이스(Food Delivery INGREDIENTS 스타일) + 실시간 인분 조절/영양소 계산
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
      backgroundColor: AppTheme.surfaceWhite,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            // 1. Food Delivery App 레퍼런스: 상단 라운드 웜 피치 비주얼 배너 + 플로팅 원형 버튼
            _buildFoodDeliveryVisualHero(
              context: context,
              recipe: recipe,
              isBookmarked: isBookmarked,
            ),
            const SizedBox(height: 18),
            // 2. 타이틀, 출처 레스토랑/플랫폼 태그, 부제 및 ⭐·🔥·⏱ 메타데이터 바
            _buildFoodDeliveryTitleAndMeta(recipe),
            const SizedBox(height: 18),
            // 3. 칼로리 및 영양 성분 계산 카드 (인분 연동)
            _buildNutritionSummaryCard(recipe),
            if (widget.recommendedRecipe.hasUncertainQuantities) ...[
              const SizedBox(height: 12),
              _buildUncertainQuantityNotice(),
            ],
            const SizedBox(height: 18),
            // 4. Food Delivery 스타일 원형 재료 아이콘 + 인분 스테퍼 및 분량 리스트
            _buildServingsAndIngredientsCard(recipe, ownedCanonicalNames),
            if (recipe.safetyWarnings.isNotEmpty) ...[
              const SizedBox(height: 18),
              _buildSafetyWarningsCard(recipe.safetyWarnings),
            ],
            const SizedBox(height: 18),
            _buildCookingStepsSection(recipe),
            const SizedBox(height: 16),
            _buildSourceFooter(recipe),
          ],
        ),
      ),
    );
  }

  /// Figma Food Delivery App 상단 웜 오렌지/피치 라운드 쇼케이스 박스 + 플로팅 원형 버튼
  Widget _buildFoodDeliveryVisualHero({
    required BuildContext context,
    required Recipe recipe,
    required bool isBookmarked,
  }) {
    final isNow =
        widget.recommendedRecipe.tier == RecommendationTier.canMakeNow;

    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFBE7D8),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          // 중앙 대형 요리 아이콘 쇼케이스
          Center(
            child: Container(
              width: 118,
              height: 118,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
              child: Text(
                recipe.emoji,
                style: const TextStyle(fontSize: 64),
              ),
            ),
          ),
          // 좌상단 플로팅 원형 뒤로가기 버튼
          Positioned(
            top: 14,
            left: 14,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                tooltip: '뒤로가기',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          // 우상단 플로팅 원형 북마크(하트/북마크) 버튼
          Positioned(
            top: 14,
            right: 14,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              child: IconButton(
                key: const Key('bookmark_toggle_button'),
                tooltip: isBookmarked ? '저장 취소' : '레시피 저장',
                onPressed: () {
                  ref.read(appStateProvider.notifier).toggleBookmark(recipe.id);
                },
                icon: Icon(
                  isBookmarked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isBookmarked
                      ? const Color(0xFFFF6B35)
                      : AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          // 좌하단 조리 가능 상태 캡슐 배지
          Positioned(
            bottom: 14,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isNow
                    ? AppTheme.primaryGreen
                    : AppTheme.espressoCharcoal,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                widget.recommendedRecipe.tier.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Food Delivery App의 타이틀 + 레스토랑/출처 칩 + ⭐ 100% · 🔥 kcal · ⏱ 20 min 인라인 바
  Widget _buildFoodDeliveryTitleAndMeta(Recipe recipe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 카테고리 및 레시피 출처 캡슐 (Food Delivery의 'Uttora Coffe House' 배지 스타일)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.warmWhite,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppTheme.borderSubtle),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_rounded,
                size: 15,
                color: AppTheme.terracotta,
              ),
              const SizedBox(width: 6),
              Text(
                '${recipe.category} · ${recipe.sourceName}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          recipe.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          recipe.subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        // Food Delivery 레퍼런스의 ⭐ 4.7   🚚 Free   ⏱ 20 min 인라인 아이콘 행
        Row(
          children: [
            const Icon(
              Icons.star_border_rounded,
              color: Color(0xFFFF7622),
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '재료 활용도 ${widget.recommendedRecipe.utilizationPercentage}%',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            const SizedBox(width: 18),
            const Icon(
              Icons.local_fire_department_outlined,
              color: Color(0xFFFF7622),
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '1인분 ${recipe.nutritionPerServing.caloriesKcal} kcal',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
            const SizedBox(width: 18),
            const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFFF7622),
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${recipe.cookingTimeMinutes}분',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
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
    );
  }

  /// 칼로리 및 탄수화물·단백질·지방·나트륨 계산 카드 (tabularFigures 적용)
  Widget _buildNutritionSummaryCard(Recipe recipe) {
    final perServing = recipe.nutritionPerServing;
    final totalScaled = perServing.scaleForServings(_currentServings);

    return Card(
      key: const Key('nutrition_summary_card'),
      color: AppTheme.warmWhite,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                  '기준: $_currentServings인분 조리 시',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 8),
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
        color: highlight ? AppTheme.terracottaLight : AppTheme.surfaceWhite,
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

  /// Food Delivery 레퍼런스의 원형 식재료 아이콘 바 + 다크 차콜 캡슐 스테퍼(- 1인분 +) 및 재료 체크리스트
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
                  'INGREDIENTS · 필요한 재료',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                // Food Delivery 레퍼런스 하단 바의 다크 차콜 캡슐형 `- 2 +` 스테퍼
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C2E),
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
            const SizedBox(height: 14),
            // Food Delivery 레퍼런스의 원형 피치 아이콘 리스트
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: recipe.coreIngredients.map((req) {
                  final canonical = IngredientNormalizer.normalizeName(req.name);
                  final cat = IngredientNormalizer.inferCategory(canonical);
                  final isOwned = ownedCanonicalNames.contains(canonical);
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isOwned
                                ? const Color(0xFFFBE7D8)
                                : AppTheme.warmWhite,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isOwned
                                  ? AppTheme.terracotta
                                  : AppTheme.borderSubtle,
                            ),
                          ),
                          child: Text(
                            cat.emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          req.name,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
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
                        color: AppTheme.terracotta,
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
        color: AppTheme.warmWhite,
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
