import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../domain/ingredient.dart';
import 'ingredient_editor_dialog.dart';

/// 홈 / 내 냉장고 식재료 및 기본 양념 관리 화면
class PantryScreen extends ConsumerStatefulWidget {
  final VoidCallback onStartScan;
  final VoidCallback onGoToRecommendations;

  const PantryScreen({
    super.key,
    required this.onStartScan,
    required this.onGoToRecommendations,
  });

  @override
  ConsumerState<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends ConsumerState<PantryScreen> {
  IngredientCategory? _selectedFilterCategory;

  Future<void> _showAddOrEditDialog([Ingredient? existing]) async {
    final result = await showDialog<Ingredient>(
      context: context,
      builder: (_) => IngredientEditorDialog(initialIngredient: existing),
    );
    if (result != null) {
      ref.read(appStateProvider.notifier).addOrUpdateIngredient(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final recommendations = ref.watch(recommendedRecipesProvider);
    final canMakeNowCount = recommendations
        .where((r) => r.tier.name == 'canMakeNow')
        .length;

    final filteredIngredients = _selectedFilterCategory == null
        ? appState.pantryIngredients
        : appState.pantryIngredients
            .where((i) => i.category == _selectedFilterCategory)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🥬 냉장고 셰프 AI'),
          ],
        ),
        actions: [
          TextButton.icon(
            key: const Key('pantry_manual_add_button'),
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('재료 직접 추가'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildHeroScanCard(
            ingredientCount: appState.pantryIngredients.length,
            canMakeNowCount: canMakeNowCount,
          ),
          const SizedBox(height: 22),
          _buildPantrySectionHeader(appState.pantryIngredients.length),
          const SizedBox(height: 10),
          _buildCategoryFilterChips(appState.pantryIngredients),
          const SizedBox(height: 12),
          if (filteredIngredients.isEmpty)
            _buildEmptyPantryCard()
          else
            ...filteredIngredients.map(_buildIngredientCard),
          const SizedBox(height: 24),
          _buildSeasoningRackSection(appState.ownedSeasonings),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroScanCard({
    required int ingredientCount,
    required int canMakeNowCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '보유 재료 $ingredientCount개 · 바로 가능 요리 $canMakeNowCount개',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '사진 한 장으로 냉장고 재료를\n채우고 오늘 요리를 추천받으세요!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('hero_start_scan_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryGreenDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: widget.onStartScan,
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('사진으로 재료 인식'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('hero_view_recommendations_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onPressed: widget.onGoToRecommendations,
                child: const Text('추천 요리 보기'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPantrySectionHeader(int totalCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '내 냉장고 보유 재료 ($totalCount)',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        TextButton.icon(
          onPressed: () => _showAddOrEditDialog(),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('수동 추가'),
        ),
      ],
    );
  }

  Widget _buildCategoryFilterChips(List<Ingredient> allIngredients) {
    final usedCategories = allIngredients.map((e) => e.category).toSet();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('전체'),
            selected: _selectedFilterCategory == null,
            onSelected: (_) => setState(() => _selectedFilterCategory = null),
          ),
          const SizedBox(width: 8),
          ...IngredientCategory.values
              .where((c) => usedCategories.contains(c))
              .map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text('${category.emoji} ${category.label}'),
                selected: _selectedFilterCategory == category,
                onSelected: (_) {
                  setState(() {
                    _selectedFilterCategory =
                        _selectedFilterCategory == category ? null : category;
                  });
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyPantryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Column(
          children: [
            const Icon(
              Icons.kitchen_outlined,
              size: 42,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 10),
            const Text(
              '등록된 식재료가 없습니다',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              '냉장고 사진을 촬영하거나 재료를 직접 추가해 보세요.',
              style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: widget.onStartScan,
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('사진 촬영/선택'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showAddOrEditDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('직접 추가'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(Ingredient item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreenLight,
          child: Text(
            item.category.emoji,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
        ),
        subtitle: Text(
          '${item.category.label} · ${item.quantityDisplay}',
          style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              key: Key('edit_ingredient_${item.name}'),
              tooltip: '재료 수정',
              onPressed: () => _showAddOrEditDialog(item),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              key: Key('delete_ingredient_${item.name}'),
              tooltip: '재료 삭제',
              onPressed: () {
                ref.read(appStateProvider.notifier).removeIngredient(item.id);
              },
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppTheme.dangerRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasoningRackSection(Set<String> ownedSeasonings) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('🧂', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '내 주방 기본 양념 & 조미료 설정',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '보유 중인 기본 양념을 체크해 두면 매번 사진을 찍지 않아도 요리 추천에 자동으로 반영됩니다.',
              style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IngredientNormalizer.defaultSeasonings.map((seasoning) {
                final isOwned = ownedSeasonings.contains(seasoning);
                return FilterChip(
                  key: Key('seasoning_chip_$seasoning'),
                  label: Text(seasoning),
                  selected: isOwned,
                  onSelected: (_) {
                    ref
                        .read(appStateProvider.notifier)
                        .toggleSeasoning(seasoning);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
