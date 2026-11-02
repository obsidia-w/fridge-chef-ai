import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipe_detail/presentation/recipe_detail_screen.dart';
import '../../recommendation/domain/recipe.dart';
import '../domain/user_preferences.dart';

/// 저장한 레시피 보관함 화면 (JavaGem Coffee Shop & Food Delivery 레퍼런스 + baseline-ui 적용)
/// - 피드백 반영:
///   1. 조리시간, 난이도, 인분 수 설정 제거
///   2. 알레르기 필터는 메인 화면에서 숨기고 우측 상단 ⚙️ 설정창(모달)을 눌렀을 때만 열리도록 분리
class SavedAndPreferencesScreen extends ConsumerWidget {
  const SavedAndPreferencesScreen({super.key});

  void _openAllergySettingsModal(BuildContext context) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final allRecipes = ref.watch(allRecipesProvider);
    final recommendations = ref.watch(recommendedRecipesProvider);

    final bookmarkedRecipes = allRecipes
        .where((r) => appState.bookmarkedRecipeIds.contains(r.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('🔖 저장한 요리 보관함'),
        actions: [
          TextButton.icon(
            key: const Key('open_settings_modal_button'),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.terracottaDark,
            ),
            onPressed: () => _openAllergySettingsModal(context),
            icon: const Icon(Icons.settings_outlined, size: 18),
            label: Text(
              appState.preferences.allergens.isEmpty
                  ? '알레르기 설정'
                  : '알레르기 설정 (${appState.preferences.allergens.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFeatures: AppTheme.tabularFigures,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildRecipeSourceGuideCard(),
          const SizedBox(height: 20),
          _buildBookmarkedRecipesSection(
            context: context,
            bookmarkedRecipes: bookmarkedRecipes,
            recommendations: recommendations,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildRecipeSourceGuideCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.public_outlined,
                  color: AppTheme.terracottaDark,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  '카테고리별 글로벌 레시피 출처 안내',
                  style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...CuisineCategory.values
                .where((c) => c != CuisineCategory.all)
                .map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '• ${c.emoji} ${c.label}: ${c.primarySourceSite}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkedRecipesSection({
    required BuildContext context,
    required List<Recipe> bookmarkedRecipes,
    required List<RecommendedRecipe> recommendations,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '저장한 레시피 (${bookmarkedRecipes.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
        const SizedBox(height: 10),
        if (bookmarkedRecipes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.terracottaLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.bookmark_border,
                      color: AppTheme.terracottaDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '아직 저장한 레시피가 없습니다. 마음에 드는 요리 상세 화면에서 북마크 아이콘을 눌러 저장해 보세요 (오프라인에서도 열람 가능).',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...bookmarkedRecipes.map((recipe) {
            final matchingRec = recommendations
                .where((r) => r.recipe.id == recipe.id)
                .firstOrNull;
            final resolvedRec = matchingRec ??
                RecommendedRecipe(
                  recipe: recipe,
                  tier: RecommendationTier.canMakeNow,
                  matchedIngredients:
                      recipe.coreIngredients.map((e) => e.name).toList(),
                  missingCoreIngredients: const [],
                  missingSeasonings: const [],
                  pantryUtilizationRatio: 1.0,
                  hasUncertainQuantities: false,
                  recommendationReason: '저장해 둔 즐겨찾기 레시피입니다.',
                );

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.terracottaLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    recipe.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                title: Text(
                  recipe.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Text(
                  '${recipe.category} · 🔥 ${recipe.nutritionPerServing.caloriesKcal}kcal · ⏱ ${recipe.cookingTimeMinutes}분',
                  style: const TextStyle(
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recommendedRecipe: resolvedRec),
                    ),
                  );
                },
              ),
            );
          }),
      ],
    );
  }
}

/// 설정창 안으로 숨겨진 알레르기 및 기피 식재료 설정 모달 시트
class AllergySettingsBottomSheet extends ConsumerWidget {
  const AllergySettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appStateProvider).preferences;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '⚙️ 알레르기 및 제외 식재료 설정',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  tooltip: '닫기',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '선택하신 알레르기 항목이 포함된 레시피는 추천 단계에서 엄격히 제외됩니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: AllergenType.values.map((allergen) {
                final isSelected = prefs.allergens.contains(allergen);
                return FilterChip(
                  key: Key('allergen_chip_${allergen.name}'),
                  label: Text(allergen.label),
                  selected: isSelected,
                  selectedColor: AppTheme.dangerRedLight,
                  checkmarkColor: AppTheme.dangerRed,
                  onSelected: (_) {
                    final next = {...prefs.allergens};
                    if (isSelected) {
                      next.remove(allergen);
                    } else {
                      next.add(allergen);
                    }
                    ref.read(appStateProvider.notifier).updatePreferences(
                          prefs.copyWith(allergens: next),
                        );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: const Text(
                '⚠️ 안전 안내: 앱의 알레르기 필터는 등록된 대표 식재료를 기준으로 작동하며, 가공식품·소스류의 미량 교차 오염이나 완전한 알레르겐 안전성을 보장하지 않습니다. 조리 전 실제 제품의 성분표를 반드시 확인하세요.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.espressoCharcoal,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('설정 완료'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
