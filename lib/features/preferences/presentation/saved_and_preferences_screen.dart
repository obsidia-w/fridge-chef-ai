import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../recipe_detail/presentation/recipe_detail_screen.dart';
import '../../recommendation/domain/recipe.dart';
import '../domain/user_preferences.dart';

/// 저장한 레시피 다시 보기 및 개인화 설정(알레르기/조리시간/난이도/인분) 화면
class SavedAndPreferencesScreen extends ConsumerWidget {
  const SavedAndPreferencesScreen({super.key});

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
        title: const Text('🔖 저장한 요리 & 맞춤 설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBookmarkedRecipesSection(
            context: context,
            bookmarkedRecipes: bookmarkedRecipes,
            recommendations: recommendations,
          ),
          const SizedBox(height: 24),
          _buildPreferencesSection(context, ref, appState.preferences),
          const SizedBox(height: 32),
        ],
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
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (bookmarkedRecipes.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.bookmark_border, color: AppTheme.textMuted),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '아직 저장한 레시피가 없습니다. 마음에 드는 요리 상세 화면에서 북마크 아이콘을 눌러 저장해 보세요 (오프라인에서도 열람 가능).',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
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
                leading: Text(
                  recipe.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
                title: Text(
                  recipe.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '⏱ ${recipe.cookingTimeMinutes}분 · 난이도 ${recipe.difficulty.label}',
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

  Widget _buildPreferencesSection(
    BuildContext context,
    WidgetRef ref,
    UserPreferences prefs,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '개인화 및 알레르기 안전 필터',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '선택하신 알레르기 항목이 포함된 레시피는 추천 단계에서 엄격히 제외됩니다.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),
            const Text(
              '알레르기 및 피해야 할 식재료',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
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
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(10),
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
            const Divider(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최대 조리 시간',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                DropdownButton<int>(
                  value: prefs.maxCookingTimeMinutes,
                  items: const [15, 30, 45, 60].map((min) {
                    return DropdownMenuItem(
                      value: min,
                      child: Text('$min분 이내'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(appStateProvider.notifier).updatePreferences(
                            prefs.copyWith(maxCookingTimeMinutes: val),
                          );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '선호 조리 난이도',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                DropdownButton<RecipeDifficulty>(
                  value: prefs.preferredDifficulty,
                  items: RecipeDifficulty.values.map((diff) {
                    return DropdownMenuItem(
                      value: diff,
                      child: Text('${diff.label} 이하'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(appStateProvider.notifier).updatePreferences(
                            prefs.copyWith(preferredDifficulty: val),
                          );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '기본 조리 인분 수',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                DropdownButton<int>(
                  value: prefs.defaultServings,
                  items: const [1, 2, 3, 4].map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text('$s인분 기준'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(appStateProvider.notifier).updatePreferences(
                            prefs.copyWith(defaultServings: val),
                          );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
