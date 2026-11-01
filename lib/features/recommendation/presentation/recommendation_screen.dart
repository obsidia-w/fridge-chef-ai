import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipe_detail/presentation/recipe_detail_screen.dart';
import '../domain/recipe.dart';

/// 보유 재료 기반 요리 추천 화면 ('지금 만들 수 있는 요리' / '조금만 추가하면 가능한 요리' 분리)
class RecommendationScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenScanner;

  const RecommendationScreen({
    super.key,
    required this.onOpenScanner,
  });

  @override
  ConsumerState<RecommendationScreen> createState() =>
      _RecommendationScreenState();
}

class _RecommendationScreenState extends ConsumerState<RecommendationScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRecipeDetail(RecommendedRecipe item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecipeDetailScreen(recommendedRecipe: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final recommendations = ref.watch(recommendedRecipesProvider);

    final canMakeNowList = recommendations
        .where((r) => r.tier == RecommendationTier.canMakeNow)
        .toList();
    final almostReadyList = recommendations
        .where((r) => r.tier == RecommendationTier.almostReady)
        .toList();

    final hasUncertainQty =
        recommendations.any((r) => r.hasUncertainQuantities);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🍳 맞춤 요리 추천'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreenDark,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryGreen,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
          tabs: [
            Tab(
              key: const Key('tab_can_make_now'),
              text: '지금 바로 가능 (${canMakeNowList.length})',
            ),
            Tab(
              key: const Key('tab_almost_ready'),
              text: '조금만 추가 (${almostReadyList.length})',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildActiveFilterSummaryBar(appState, hasUncertainQty),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipeList(
                  items: canMakeNowList,
                  emptyTitle: '지금 바로 만들 수 있는 요리가 없어요',
                  emptySubtitle:
                      '냉장고 사진을 찍어 식재료를 추가하거나 [조금만 추가] 탭을 확인해 보세요.',
                ),
                _buildRecipeList(
                  items: almostReadyList,
                  emptyTitle: '조금만 추가하면 가능한 요리가 없어요',
                  emptySubtitle: '식재료를 더 등록하거나 조리 시간/난이도 조건을 넓혀 보세요.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterSummaryBar(
    AppDataState appState,
    bool hasUncertainQty,
  ) {
    final prefs = appState.preferences;
    final allergenText = prefs.allergens.isEmpty
        ? '알레르기 필터 없음'
        : '제외됨: ${prefs.allergens.map((a) => a.label).join(', ')}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppTheme.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildFilterChipTag(
                '⏱ 최대 ${prefs.maxCookingTimeMinutes}분',
              ),
              _buildFilterChipTag(
                '📊 난이도 ${prefs.preferredDifficulty.label} 이하',
              ),
              _buildFilterChipTag('🛡 $allergenText'),
            ],
          ),
          if (hasUncertainQty) ...[
            const SizedBox(height: 6),
            const Text(
              '※ 수량을 입력하지 않은 재료가 포함되어 있어 실제 보유 분량에 따라 조리 가능 여부가 달라질 수 있습니다.',
              style: TextStyle(
                fontSize: 11.5,
                color: AppTheme.accentAmberDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChipTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warmWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11.5,
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRecipeList({
    required List<RecommendedRecipe> items,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant_menu_outlined,
                size: 46,
                color: AppTheme.textMuted,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: widget.onOpenScanner,
                icon: const Icon(Icons.camera_alt_outlined, size: 18),
                label: const Text('냉장고 재료 스캔하기'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return _buildRecipeCard(item);
      },
    );
  }

  Widget _buildRecipeCard(RecommendedRecipe item) {
    final recipe = item.recipe;
    final isNow = item.tier == RecommendationTier.canMakeNow;

    return Card(
      key: Key('recipe_card_${recipe.id}'),
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openRecipeDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isNow
                          ? AppTheme.primaryGreenLight
                          : AppTheme.accentAmberLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      recipe.emoji,
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isNow
                                    ? AppTheme.primaryGreenLight
                                    : AppTheme.accentAmberLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isNow
                                    ? '바로 조리 가능'
                                    : '재료 ${item.missingCoreIngredients.length}개 부족',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isNow
                                      ? AppTheme.primaryGreenDark
                                      : AppTheme.accentAmberDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '활용도 ${item.utilizationPercentage}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recipe.title,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '⏱ ${recipe.cookingTimeMinutes}분 · 난이도 ${recipe.difficulty.label} · ${recipe.category}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppTheme.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...item.matchedIngredients.map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreenLight.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '✓ $name',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryGreenDark,
                        ),
                      ),
                    ),
                  ),
                  ...item.missingCoreIngredients.map(
                    (name) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmberLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+ 부족: $name',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.accentAmberDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.recommendationReason,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
