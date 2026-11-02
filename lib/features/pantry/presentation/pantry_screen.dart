import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../domain/ingredient.dart';
import 'ingredient_editor_dialog.dart';

/// 홈 / 내 냉장고 식재료, 메인 재료 지정 및 기본 양념 관리 화면
/// - JavaGem Coffee Shop 다크 히어로 대시보드 + Food Delivery 카드 UI 적용
/// - baseline-ui: 그라데이션 제거, 고정폭 숫자(tabularFigures), 삭제 시 확인 모달(AlertDialog), 빈 상태 단일 CTA 적용
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

  Future<void> _confirmAndDeleteIngredient(Ingredient item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '식재료 삭제 확인',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        content: Text(
          '\'${item.name}\'을(를) 내 냉장고 목록에서 삭제할까요?',
          style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            key: Key('confirm_delete_ingredient_${item.name}'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(appStateProvider.notifier).removeIngredient(item.id);
    }
  }

  void _selectAsMainAndGoToRecommendations(String ingredientName) {
    final currentMain = ref.read(appStateProvider).selectedMainIngredient;
    if (currentMain != ingredientName) {
      ref.read(appStateProvider.notifier).selectMainIngredient(ingredientName);
    }
    widget.onGoToRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final recommendations = ref.watch(recommendedRecipesProvider);
    final canMakeNowCount =
        recommendations.where((r) => r.tier.name == 'canMakeNow').length;

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
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.terracottaDark,
            ),
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text(
              '재료 직접 추가',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          _buildHeroScanCard(
            ingredientCount: appState.pantryIngredients.length,
            canMakeNowCount: canMakeNowCount,
          ),
          const SizedBox(height: 24),
          _buildPantrySectionHeader(appState.pantryIngredients.length),
          const SizedBox(height: 6),
          const Text(
            '식재료 카드의 [🎯 메인 추천]을 누르면 해당 재료를 주인공으로 하는 레시피만 바로 모아볼 수 있어요.',
            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          _buildCategoryFilterChips(appState.pantryIngredients),
          const SizedBox(height: 14),
          if (filteredIngredients.isEmpty)
            _buildEmptyPantryCard()
          else
            ...filteredIngredients.map(
              (item) => _buildIngredientCard(
                item,
                isMainSelected: appState.selectedMainIngredient == item.name,
              ),
            ),
          const SizedBox(height: 24),
          _buildSeasoningRackSection(appState.ownedSeasonings),
        ],
      ),
    );
  }

  /// JavaGem Coffee Shop 레퍼런스 스타일의 솔리드 딥 차콜 히어로 카드 (No AI-slop gradient)
  Widget _buildHeroScanCard({
    required int ingredientCount,
    required int canMakeNowCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.espressoCharcoal,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.espressoMuted, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.terracotta,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'AI KITCHEN STUDIO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '보유 $ingredientCount개 · 바로 가능 $canMakeNowCount개',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFFD6D3D1),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: AppTheme.tabularFigures,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            '카메라로 냉장고 재료를 촬영하고\n오늘의 맞춤 요리를 만나보세요',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  key: const Key('hero_start_scan_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.terracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: widget.onStartScan,
                  icon: const Icon(Icons.camera_alt_rounded, size: 19),
                  label: const Text('카메라로 재료 인식'),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                key: const Key('hero_view_recommendations_button'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: AppTheme.espressoMuted,
                  side: const BorderSide(color: Color(0xFF44403C)),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            fontFeatures: AppTheme.tabularFigures,
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.terracottaDark,
          ),
          onPressed: () => _showAddOrEditDialog(),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text(
            '수동 추가',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
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

  /// baseline-ui 규칙: 빈 상태(Empty State)는 하나의 명확한 다음 행동(Single Primary CTA)만 강조
  Widget _buildEmptyPantryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.terracottaLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.kitchen_outlined,
                size: 28,
                color: AppTheme.terracottaDark,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '등록된 식재료가 없습니다',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text(
              '카메라로 냉장고를 촬영하면 AI가 식재료를 한 번에 정리해 드려요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
              ),
              onPressed: widget.onStartScan,
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('카메라로 재료 인식하기'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientCard(
    Ingredient item, {
    required bool isMainSelected,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isMainSelected ? AppTheme.terracotta : AppTheme.borderSubtle,
          width: isMainSelected ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isMainSelected
                    ? AppTheme.terracottaLight
                    : AppTheme.warmWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.borderSubtle),
              ),
              child: Text(
                item.category.emoji,
                style: const TextStyle(fontSize: 22),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ),
                      if (isMainSelected) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.terracottaLight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            '🎯 메인 선택됨',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.terracottaDark,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.category.label} · ${item.quantityDisplay}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textSecondary,
                      fontFeatures: AppTheme.tabularFigures,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              key: Key('select_main_from_pantry_${item.name}'),
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.terracottaLight,
                foregroundColor: AppTheme.terracottaDark,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _selectAsMainAndGoToRecommendations(item.name),
              child: const Text(
                '🎯 메인 추천',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              key: Key('edit_ingredient_${item.name}'),
              tooltip: '재료 수정',
              visualDensity: VisualDensity.compact,
              onPressed: () => _showAddOrEditDialog(item),
              icon: const Icon(Icons.edit_outlined, size: 19),
            ),
            IconButton(
              key: Key('delete_ingredient_${item.name}'),
              tooltip: '재료 삭제',
              visualDensity: VisualDensity.compact,
              onPressed: () => _confirmAndDeleteIngredient(item),
              icon: const Icon(
                Icons.delete_outline,
                size: 19,
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
        padding: const EdgeInsets.all(18),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
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
