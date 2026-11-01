import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/ingredient_normalizer.dart';
import '../../features/pantry/domain/ingredient.dart';
import '../../features/preferences/domain/user_preferences.dart';
import '../../features/recommendation/data/verified_recipes_data.dart';
import '../../features/recommendation/domain/recipe.dart';
import '../../features/recommendation/domain/recipe_recommendation_engine.dart';
import '../../features/scanner/data/ingredient_scanner_service.dart';

/// 로컬 저장소 및 전체 앱 상태(내 냉장고 재료, 기본 양념, 개인화 설정, 저장한 레시피) 통합 모델
class AppDataState {
  final List<Ingredient> pantryIngredients;
  final Set<String> ownedSeasonings;
  final UserPreferences preferences;
  final Set<String> bookmarkedRecipeIds;
  final bool isInitialized;

  const AppDataState({
    required this.pantryIngredients,
    required this.ownedSeasonings,
    required this.preferences,
    required this.bookmarkedRecipeIds,
    this.isInitialized = false,
  });

  factory AppDataState.initial() {
    return AppDataState(
      pantryIngredients: const [
        Ingredient(
          id: 'init_egg',
          name: '계란',
          category: IngredientCategory.eggDairy,
          quantity: 6,
          unit: '개',
        ),
        Ingredient(
          id: 'init_kimchi',
          name: '김치',
          category: IngredientCategory.processed,
        ),
        Ingredient(
          id: 'init_green_onion',
          name: '대파',
          category: IngredientCategory.vegetable,
          quantity: 1,
          unit: '대',
        ),
        Ingredient(
          id: 'init_rice',
          name: '밥',
          category: IngredientCategory.grain,
          quantity: 2,
          unit: '공기',
        ),
      ],
      ownedSeasonings: {
        '소금',
        '설탕',
        '간장',
        '고추장',
        '고춧가루',
        '된장',
        '식용유',
        '참기름',
        '마늘',
        '후추',
      },
      preferences: const UserPreferences(),
      bookmarkedRecipeIds: const {},
      isInitialized: false,
    );
  }

  AppDataState copyWith({
    List<Ingredient>? pantryIngredients,
    Set<String>? ownedSeasonings,
    UserPreferences? preferences,
    Set<String>? bookmarkedRecipeIds,
    bool? isInitialized,
  }) {
    return AppDataState(
      pantryIngredients: pantryIngredients ?? this.pantryIngredients,
      ownedSeasonings: ownedSeasonings ?? this.ownedSeasonings,
      preferences: preferences ?? this.preferences,
      bookmarkedRecipeIds: bookmarkedRecipeIds ?? this.bookmarkedRecipeIds,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// 앱 전역 상태 및 오프라인 영속성 Notifier
class AppStateNotifier extends Notifier<AppDataState> {
  static const _kPantryKey = 'fridge_chef_pantry_v1';
  static const _kSeasoningsKey = 'fridge_chef_seasonings_v1';
  static const _kPreferencesKey = 'fridge_chef_preferences_v1';
  static const _kBookmarksKey = 'fridge_chef_bookmarks_v1';

  @override
  AppDataState build() {
    _loadFromStorage();
    return AppDataState.initial();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<Ingredient>? loadedIngredients;
      final pantryJson = prefs.getString(_kPantryKey);
      if (pantryJson != null) {
        final decoded = jsonDecode(pantryJson) as List<dynamic>;
        loadedIngredients = decoded
            .map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      Set<String>? loadedSeasonings;
      final seasoningsList = prefs.getStringList(_kSeasoningsKey);
      if (seasoningsList != null) {
        loadedSeasonings = seasoningsList.toSet();
      }

      UserPreferences? loadedPrefs;
      final prefsJson = prefs.getString(_kPreferencesKey);
      if (prefsJson != null) {
        loadedPrefs = UserPreferences.fromJson(
          jsonDecode(prefsJson) as Map<String, dynamic>,
        );
      }

      Set<String>? loadedBookmarks;
      final bookmarksList = prefs.getStringList(_kBookmarksKey);
      if (bookmarksList != null) {
        loadedBookmarks = bookmarksList.toSet();
      }

      state = state.copyWith(
        pantryIngredients: loadedIngredients,
        ownedSeasonings: loadedSeasonings,
        preferences: loadedPrefs,
        bookmarkedRecipeIds: loadedBookmarks,
        isInitialized: true,
      );
    } catch (_) {
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kPantryKey,
        jsonEncode(state.pantryIngredients.map((e) => e.toJson()).toList()),
      );
      await prefs.setStringList(
        _kSeasoningsKey,
        state.ownedSeasonings.toList(),
      );
      await prefs.setString(
        _kPreferencesKey,
        jsonEncode(state.preferences.toJson()),
      );
      await prefs.setStringList(
        _kBookmarksKey,
        state.bookmarkedRecipeIds.toList(),
      );
    } catch (_) {
      // 테스트 환경이나 스토리지 접근 실패 시 인메모리 상태는 유지
    }
  }

  /// 식재료 단건 추가 또는 병합
  void addOrUpdateIngredient(Ingredient ingredient) {
    final normalizedName = IngredientNormalizer.normalizeName(ingredient.name);
    if (normalizedName.isEmpty ||
        IngredientNormalizer.isNonFoodItem(normalizedName)) {
      return;
    }

    final category = IngredientNormalizer.inferCategory(
      normalizedName,
      ingredient.category,
    );
    final updatedItem = ingredient.copyWith(
      name: normalizedName,
      category: category,
      isVerified: true,
    );

    final existingIndex = state.pantryIngredients.indexWhere(
      (e) => e.id == updatedItem.id || e.name == updatedItem.name,
    );

    final newList = [...state.pantryIngredients];
    if (existingIndex >= 0) {
      newList[existingIndex] = updatedItem;
    } else {
      newList.add(updatedItem);
    }

    state = state.copyWith(
      pantryIngredients: IngredientNormalizer.normalizeAndDeduplicate(newList),
    );
    _saveToStorage();
  }

  /// AI 인식 및 사용자 검수를 마친 식재료 목록을 냉장고에 일괄 반영
  void mergeVerifiedScanResults(
    List<Ingredient> verifiedItems, {
    bool replaceExisting = false,
  }) {
    final cleanedItems = verifiedItems
        .map((e) => e.copyWith(isVerified: true))
        .toList();

    final combined = replaceExisting
        ? cleanedItems
        : [...state.pantryIngredients, ...cleanedItems];

    state = state.copyWith(
      pantryIngredients: IngredientNormalizer.normalizeAndDeduplicate(combined),
    );
    _saveToStorage();
  }

  /// 식재료 삭제
  void removeIngredient(String id) {
    state = state.copyWith(
      pantryIngredients:
          state.pantryIngredients.where((e) => e.id != id).toList(),
    );
    _saveToStorage();
  }

  /// 전체 식재료 비우기
  void clearPantry() {
    state = state.copyWith(pantryIngredients: const []);
    _saveToStorage();
  }

  /// 기본 양념 보유 여부 토글
  void toggleSeasoning(String seasoningName) {
    final next = {...state.ownedSeasonings};
    if (next.contains(seasoningName)) {
      next.remove(seasoningName);
    } else {
      next.add(seasoningName);
    }
    state = state.copyWith(ownedSeasonings: next);
    _saveToStorage();
  }

  /// 개인화 설정 업데이트
  void updatePreferences(UserPreferences newPreferences) {
    state = state.copyWith(preferences: newPreferences);
    _saveToStorage();
  }

  /// 레시피 북마크 토글
  void toggleBookmark(String recipeId) {
    final next = {...state.bookmarkedRecipeIds};
    if (next.contains(recipeId)) {
      next.remove(recipeId);
    } else {
      next.add(recipeId);
    }
    state = state.copyWith(bookmarkedRecipeIds: next);
    _saveToStorage();
  }
}

final appStateProvider = NotifierProvider<AppStateNotifier, AppDataState>(
  AppStateNotifier.new,
);

final scannerServiceProvider = Provider<IngredientScannerService>((ref) {
  return GeminiIngredientScannerService();
});

final allRecipesProvider = Provider<List<Recipe>>((ref) {
  return VerifiedRecipesData.recipes;
});

final recommendedRecipesProvider = Provider<List<RecommendedRecipe>>((ref) {
  final appState = ref.watch(appStateProvider);
  final allRecipes = ref.watch(allRecipesProvider);
  const engine = RecipeRecommendationEngine();

  return engine.recommend(
    pantryIngredients: appState.pantryIngredients,
    ownedSeasonings: appState.ownedSeasonings,
    preferences: appState.preferences,
    allRecipes: allRecipes,
  );
});
