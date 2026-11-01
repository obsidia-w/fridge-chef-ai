import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../../recommendation/domain/recipe.dart';

/// 레시피 상세 화면 (인분 조절, 필요 재료 체크, 단계별 조리 방법, 식품 안전 주의사항, 대체안, 북마크)
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
    final defaultServings =
        ref.read(appStateProvider).preferences.defaultServings;
    _currentServings = defaultServings > 0
        ? defaultServings
        : widget.recommendedRecipe.recipe.baseServings;
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
              color: isBookmarked ? AppTheme.primaryGreen : AppTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeaderCard(recipe),
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
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(recipe.emoji, style: const TextStyle(fontSize: 36)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.recommendedRecipe.tier.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isNow
                                ? AppTheme.primaryGreenDark
                                : AppTheme.accentAmberDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recipe.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              recipe.subtitle,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildInfoBadge(
                  Icons.schedule_outlined,
                  '예상 ${recipe.cookingTimeMinutes}분',
                ),
                _buildInfoBadge(
                  Icons.bar_chart_rounded,
                  '난이도 ${recipe.difficulty.label}',
                ),
                _buildInfoBadge(
                  Icons.kitchen_outlined,
                  '보유 재료 활용도 ${widget.recommendedRecipe.utilizationPercentage}%',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '💡 추천 이유: ${widget.recommendedRecipe.recommendationReason}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
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
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildServingsAndIngredientsCard(
    Recipe recipe,
    Set<String> ownedCanonicalNames,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '필요한 재료와 분량',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.warmWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        key: const Key('servings_decrease_button'),
                        visualDensity: VisualDensity.compact,
                        onPressed:
                            _currentServings > 1 ? () => _changeServings(-1) : null,
                        icon: const Icon(Icons.remove, size: 18),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$_currentServings인분',
                          key: const Key('servings_count_text'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('servings_increase_button'),
                        visualDensity: VisualDensity.compact,
                        onPressed: _currentServings < 10
                            ? () => _changeServings(1)
                            : null,
                        icon: const Icon(Icons.add, size: 18),
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
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
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
        borderRadius: BorderRadius.circular(16),
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
                  fontWeight: FontWeight.w700,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '단계별 조리 방법 (초보자 가이드)',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...recipe.steps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppTheme.primaryGreen,
                      child: Text(
                        '${step.stepNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
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
                                color: AppTheme.warmWhite,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '💡 초보 팁: ${step.tip}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textSecondary,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '출처: ${recipe.sourceName} · 알레르기 유발 성분은 조리 전 제품 원재료명을 반드시 직접 확인하세요.',
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
    );
  }
}
