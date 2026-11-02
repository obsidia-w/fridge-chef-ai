import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../preferences/domain/user_preferences.dart';
import '../../preferences/presentation/saved_and_preferences_screen.dart';
import '../../recipe_detail/presentation/recipe_detail_screen.dart';
import '../domain/recipe.dart';

/// 보유 재료 기반 요리 추천 화면
/// - 피드백 반영:
///   1. 요리 카테고리 필터 (전체, 한식, 양식, 일식, 중식, 동남아)
///   2. 메인 재료(주인공 식재료) 선택 필터 바
///   3. 칼로리 및 단백질 등 영양소 요약 배지 표시
///   4. 알레르기 필터는 상단 설정 아이콘(⚙️) 안으로 숨김
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

  void _openAllergySettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const AllergySettingsBottomSheet(),
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
        actions: [
          IconButton(
            key: const Key('open_allergy_settings_button'),
            tooltip: '알레르기 필터 설정',
            onPressed: _openAllergySettingsSheet,
            icon: Badge(
              isLabelVisible: appState.preferences.allergens.isNotEmpty,
              label: Text('${appState.preferences.allergens.length}'),
              child: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(width: 8),
        ],
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
          _buildCategoryAndMainIngredientFilterSection(
            appState: appState,
            hasUncertainQty: hasUncertainQty,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecipeList(
                  items: canMakeNowList,
                  emptyTitle: '조건에 맞는 바로 가능 요리가 없어요',
                  emptySubtitle:
                      '다른 요리 카테고리나 메인 재료를 선택하거나 [조금만 추가] 탭을 확인해 보세요.',
                ),
                _buildRecipeList(
                  items: almostReadyList,
                  emptyTitle: '조금만 추가하면 가능한 요리가 없어요',
                  emptySubtitle: '식재료를 더 등록하거나 다른 요리 카테고리를 선택해 보세요.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryAndMainIngredientFilterSection({
    required AppDataState appState,
    required bool hasUncertainQty,
  }) {
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
          // 1. 요리 카테고리 필터 (전체, 한식, 양식, 일식, 중식, 동남아)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CuisineCategory.values.map((category) {
                final isSelected = appState.selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    key: Key('cuisine_chip_${category.name}'),
                    label: Text('${category.emoji} ${category.label}'),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(appStateProvider.notifier)
                          .selectCategory(category);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          // 2. 메인 재료 선택 바 (냉장고에 있는 재료를 주인공으로 하는 레시피 추천)
          if (appState.pantryIngredients.isNotEmpty) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const Text(
                    '🎯 메인 재료 선택:',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    key: const Key('main_ingredient_all_chip'),
                    visualDensity: VisualDensity.compact,
                    label: const Text('전체 재료'),
                    selected: appState.selectedMainIngredient == null,
                    onSelected: (_) {
                      ref
                          .read(appStateProvider.notifier)
                          .selectMainIngredient(null);
                    },
                  ),
                  const SizedBox(width: 6),
                  ...appState.pantryIngredients.map((ing) {
                    final isSelected =
                        appState.selectedMainIngredient == ing.name;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        key: Key('main_ingredient_chip_${ing.name}'),
                        visualDensity: VisualDensity.compact,
                        label: Text('${ing.category.emoji} ${ing.name}'),
                        selected: isSelected,
                        onSelected: (_) {
                          ref
                              .read(appStateProvider.notifier)
                              .selectMainIngredient(ing.name);
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
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
    final nutrition = recipe.nutritionPerServing;

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
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.warmWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.borderSubtle),
                              ),
                              child: Text(
                                recipe.category,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
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
                        const SizedBox(height: 4),
                        Text(
                          '🔥 ${nutrition.caloriesKcal}kcal · 단백질 ${nutrition.proteinGrams}g · ⏱ ${recipe.cookingTimeMinutes}분',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
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
                        color:
                            AppTheme.primaryGreenLight.withValues(alpha: 0.6),
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
