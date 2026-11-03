import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_state_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ingredient_normalizer.dart';
import '../../preferences/domain/user_preferences.dart';
import '../../recipe_detail/presentation/recipe_detail_screen.dart';
import '../../recommendation/domain/recipe.dart';
import '../domain/ingredient.dart';
import 'ingredient_editor_dialog.dart';

/// 홈 화면 (JavaGem Coffee Shop Mobile App + Yamesh_SB Food Delivery App UI 레퍼런스 직관 반영)
/// - 상단 풀블리드 딥 차콜 헤더(#131313) + 검색/스캔 바 + 경계선 오버랩 프로모 배너
/// - 홈 화면 첫 영역에 글로벌 요리 카테고리 알약 탭(전체, 한식, 양식, 일식, 중식, 동남아) + 2열 그리드 레시피 카드 즉시 노출
/// - 하단에 내 냉장고 식재료 관리(🎯 메인 재료 원터치 지정) 및 기본 양념 체크리스트 배치
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
    final canMakeNowCount =
        recommendations.where((r) => r.tier.name == 'canMakeNow').length;

    final filteredIngredients = _selectedFilterCategory == null
        ? appState.pantryIngredients
        : appState.pantryIngredients
            .where((i) => i.category == _selectedFilterCategory)
            .toList();

    final previewRecipes = recommendations.take(4).toList();

    return Scaffold(
      backgroundColor: AppTheme.warmWhite,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          // 1. JavaGem Coffee Shop 레퍼런스: 다크 차콜 상단 헤더 + 오버랩 프로모 스캔 배너
          _buildCoffeeShopDarkHeaderAndOverlapBanner(
            ingredientCount: appState.pantryIngredients.length,
            canMakeNowCount: canMakeNowCount,
          ),
          const SizedBox(height: 18),

          // 2. 홈 화면에서 즉시 조작 가능한 글로벌 요리 카테고리 알약 바 (전체, 한식, 양식, 일식, 중식, 동남아)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '세계 요리 카테고리별 추천',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onGoToRecommendations,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.terracottaDark,
                      ),
                      child: const Text(
                        '전체보기 →',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildHomeCuisineCategoryPills(appState.selectedCategory),
                if (appState.pantryIngredients.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _buildHomeMainIngredientPills(appState),
                ],
                const SizedBox(height: 14),
                // 3. JavaGem Coffee Shop 2열 그리드 스타일의 요리 카드 프리뷰
                _buildTwoColumnRecipeGrid(previewRecipes),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // 4. 내 냉장고 보유 식재료 섹션
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPantrySectionHeader(appState.pantryIngredients.length),
                const SizedBox(height: 4),
                const Text(
                  '재료를 눌러 [🎯 메인 추천]을 선택하면 해당 식재료가 주인공인 요리만 즉시 필터링됩니다.',
                  style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                _buildCategoryFilterChips(appState.pantryIngredients),
                const SizedBox(height: 12),
                if (filteredIngredients.isEmpty)
                  _buildEmptyPantryCard()
                else
                  ...filteredIngredients.map(
                    (item) => _buildIngredientCard(
                      item,
                      isMainSelected:
                          appState.selectedMainIngredient == item.name,
                    ),
                  ),
                const SizedBox(height: 24),
                _buildSeasoningRackSection(appState.ownedSeasonings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Figma Reference 2 (JavaGem Coffee Shop Mobile App) 스타일:
  /// 상단 딥 차콜 배경(#131313) + 다크 서치/상태 바 + 테라코타 스캔 버튼 + 경계선에 걸친 오버랩 배너
  Widget _buildCoffeeShopDarkHeaderAndOverlapBanner({
    required int ingredientCount,
    required int canMakeNowCount,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 배경 다크 차콜 컨테이너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 52, 20, 96),
          decoration: const BoxDecoration(
            color: Color(0xFF131313),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 위치/타이틀 바 + 재료 직접 추가 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI KITCHEN STUDIO',
                        style: TextStyle(
                          color: Color(0xFFA2A2A2),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            '냉장고 셰프 AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppTheme.terracotta,
                            size: 20,
                          ),
                        ],
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    key: const Key('pantry_manual_add_button'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFF2A2A2A),
                      side: const BorderSide(color: Color(0xFF3D3D3D)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _showAddOrEditDialog(),
                    icon: const Icon(
                      Icons.add_rounded,
                      size: 17,
                      color: AppTheme.terracotta,
                    ),
                    label: const Text(
                      '재료 직접 추가',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // JavaGem 스타일 다크 검색/상태 바 + 우측 정사각형 테라코타 필터/스캔 버튼
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: widget.onGoToRecommendations,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2A2A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.search_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '보유 재료 $ingredientCount개 · 바로 조리 가능 $canMakeNowCount개',
                                style: const TextStyle(
                                  color: Color(0xFFD8D8D8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: AppTheme.tabularFigures,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Material(
                    color: AppTheme.terracotta,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: widget.onStartScan,
                      child: const SizedBox(
                        width: 50,
                        height: 50,
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 경계선 아래로 겹쳐 내려오는 JavaGem Promo 스타일 히어로 카드
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 186, 20, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF26201D),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.terracotta.withValues(alpha: 0.45),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFED5151),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '4-Zone AI Vision + OCR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      '🍱🍳🥗🍜',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: const Color(0xFF131313),
                  child: const Text(
                    '냉장고 사진 한 장으로 끝내는',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  color: const Color(0xFF131313),
                  child: const Text(
                    '글로벌 맞춤 셰프 레시피 & 영양 분석',
                    style: TextStyle(
                      color: AppTheme.terracottaLight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        key: const Key('hero_start_scan_button'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.terracotta,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: widget.onStartScan,
                        icon: const Icon(Icons.camera_alt_rounded, size: 18),
                        label: const Text('카메라로 재료 인식'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      key: const Key('hero_view_recommendations_button'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF131313),
                        side: const BorderSide(color: Color(0xFF4A423E)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
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
          ),
        ),
      ],
    );
  }

  /// 홈 화면 상단 글로벌 요리 카테고리 알약 탭 (전체, 한식, 양식, 일식, 중식, 동남아)
  Widget _buildHomeCuisineCategoryPills(CuisineCategory selectedCategory) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: CuisineCategory.values.map((category) {
          final isSelected = selectedCategory == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              key: Key('home_cuisine_pill_${category.name}'),
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                ref.read(appStateProvider.notifier).selectCategory(category);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppTheme.terracotta : AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.terracotta
                        : AppTheme.borderSubtle,
                  ),
                ),
                child: Text(
                  '${category.emoji} ${category.label}',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight:
                        isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// 홈 화면 메인 재료 원터치 알약 바
  Widget _buildHomeMainIngredientPills(AppDataState appState) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.espressoCharcoal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '🎯 주인공 재료',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            visualDensity: VisualDensity.compact,
            label: const Text('전체 재료'),
            selected: appState.selectedMainIngredient == null,
            onSelected: (_) {
              ref.read(appStateProvider.notifier).selectMainIngredient(null);
            },
          ),
          const SizedBox(width: 6),
          ...appState.pantryIngredients.map((ing) {
            final isSelected = appState.selectedMainIngredient == ing.name;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
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
    );
  }

  /// Figma Reference 2 (JavaGem Coffee Shop) 2열 그리드 레시피 카드 레이아웃
  Widget _buildTwoColumnRecipeGrid(List<RecommendedRecipe> recipes) {
    if (recipes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(
                Icons.restaurant_menu_outlined,
                color: AppTheme.terracottaDark,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '선택한 카테고리/메인 재료에 해당하는 요리가 없습니다. 다른 카테고리를 눌러보세요!',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  ref
                      .read(appStateProvider.notifier)
                      .selectCategory(CuisineCategory.all);
                  ref
                      .read(appStateProvider.notifier)
                      .selectMainIngredient(null);
                },
                child: const Text('필터 초기화'),
              ),
            ],
          ),
        ),
      );
    }

    final List<Widget> rows = [];
    for (var i = 0; i < recipes.length; i += 2) {
      final first = recipes[i];
      final second = (i + 1 < recipes.length) ? recipes[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(bottom: i + 2 < recipes.length ? 12 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCoffeeShopGridCard(first)),
              const SizedBox(width: 12),
              Expanded(
                child: second != null
                    ? _buildCoffeeShopGridCard(second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  /// JavaGem Coffee Shop 상품 카드 디자인을 그대로 적용한 레시피 카드:
  /// - 상단 라운드 비주얼 영역 + 좌측 상단 `★ 활용도%` 다크 캡슐 배지
  /// - 중단 요리 제목 + 카테고리/출처 부제
  /// - 하단 좌측 칼로리(kcal) + 우측 32x32 정사각형 테라코타 `+` 액션 버튼
  Widget _buildCoffeeShopGridCard(RecommendedRecipe item) {
    final recipe = item.recipe;
    final isNow = item.tier == RecommendationTier.canMakeNow;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openRecipeDetail(item),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 비주얼 이미지 박스 + 좌상단 평점/활용도 배지
              Container(
                height: 104,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isNow
                      ? const Color(0xFFECFDF3)
                      : AppTheme.terracottaLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Text(
                        recipe.emoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131313).withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: Color(0xFFFBBE21),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${item.utilizationPercentage}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                fontFeatures: AppTheme.tabularFigures,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isNow
                              ? AppTheme.primaryGreen
                              : AppTheme.terracottaDark,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isNow
                              ? '바로 가능'
                              : '+${item.missingCoreIngredients.length}개 부족',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                recipe.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${recipe.category} · ${recipe.sourceName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${recipe.nutritionPerServing.caloriesKcal} kcal',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                      Text(
                        '단백질 ${recipe.nutritionPerServing.proteinGrams}g · ${recipe.cookingTimeMinutes}분',
                        style: const TextStyle(
                          fontSize: 10.5,
                          color: AppTheme.textSecondary,
                          fontFeatures: AppTheme.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppTheme.terracotta,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
