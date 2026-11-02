import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fridge_chef_ai/core/utils/ingredient_normalizer.dart';
import 'package:fridge_chef_ai/features/pantry/domain/ingredient.dart';
import 'package:fridge_chef_ai/features/preferences/domain/user_preferences.dart';
import 'package:fridge_chef_ai/features/recommendation/data/verified_recipes_data.dart';
import 'package:fridge_chef_ai/features/recommendation/domain/recipe.dart';
import 'package:fridge_chef_ai/features/recommendation/domain/recipe_recommendation_engine.dart';
import 'package:fridge_chef_ai/features/scanner/data/ingredient_scanner_service.dart';
import 'package:fridge_chef_ai/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. 식재료 한국어 표준화, 동의어 병합 및 비식품 제외 테스트', () {
    test('동의어(달걀, 유정란, 손질대파, 스팸 등)를 표준 한국어 명칭으로 정규화한다', () {
      expect(IngredientNormalizer.normalizeName('달걀'), '계란');
      expect(IngredientNormalizer.normalizeName('유정란'), '계란');
      expect(IngredientNormalizer.normalizeName('대파(손질)'), '대파');
      expect(IngredientNormalizer.normalizeName('스팸'), '스팸/통조림햄');
      expect(IngredientNormalizer.normalizeName('돼지고기 삼겹살'), '삼겹살');
    });

    test('비식품(반찬통, 비닐봉지, 그릇 등)을 정확히 판별하여 제외한다', () {
      expect(IngredientNormalizer.isNonFoodItem('플라스틱 반찬통'), isTrue);
      expect(IngredientNormalizer.isNonFoodItem('비닐봉지'), isTrue);
      expect(IngredientNormalizer.isNonFoodItem('락앤락 용기'), isTrue);
      expect(IngredientNormalizer.isNonFoodItem('계란'), isFalse);
      expect(IngredientNormalizer.isNonFoodItem('김치'), isFalse);
    });

    test('중복 인식된 식재료를 하나로 병합하고 비식품을 제거하며 불확실 항목을 우선 정렬한다', () {
      final rawItems = [
        const Ingredient(
          id: '1',
          name: '달걀',
          category: IngredientCategory.eggDairy,
          quantity: 3,
          unit: '개',
          confidence: RecognitionConfidence.medium,
          isVerified: false,
        ),
        const Ingredient(
          id: '2',
          name: '계란',
          category: IngredientCategory.eggDairy,
          quantity: 3,
          unit: '개',
          confidence: RecognitionConfidence.high,
          isVerified: true,
        ),
        const Ingredient(
          id: '3',
          name: '락앤락 용기',
          category: IngredientCategory.other,
        ),
        const Ingredient(
          id: '4',
          name: '찌개용 두부',
          category: IngredientCategory.eggDairy,
          confidence: RecognitionConfidence.low,
          isVerified: false,
        ),
      ];

      final normalized = IngredientNormalizer.normalizeAndDeduplicate(rawItems);

      expect(normalized.length, 2);
      expect(normalized.first.name, '두부');
      expect(normalized.first.needsConfirmation, isTrue);

      final egg = normalized.firstWhere((e) => e.name == '계란');
      expect(egg.quantity, 6);
      expect(egg.confidence, RecognitionConfidence.high);
    });
  });

  group('2. AI JSON 응답 검증기 및 환각 방지 테스트', () {
    test('AI가 임의로 생성한 수량/유통기한은 무시하고 불확실한 항목에 확인 요청 플래그를 부여한다', () {
      const sampleAiJson = '''
      {
        "ingredients": [
          {"name": "달걀", "category": "eggDairy", "confidence": "high", "isFood": true, "quantity": 99, "expiryDate": "2026-12-31"},
          {"name": "비닐봉지", "category": "other", "confidence": "high", "isFood": false},
          {"name": "두부", "category": "eggDairy", "confidence": "low", "isFood": true, "uncertaintyNote": "용기에 가려져 확인이 필요해요"}
        ]
      }
      ''';

      final result = AiResponseValidator.validateAndParse(sampleAiJson);

      expect(result.excludedNonFoodItems, contains('비닐봉지'));
      expect(result.recognizedIngredients.length, 2);

      final egg =
          result.recognizedIngredients.firstWhere((e) => e.name == '계란');
      expect(egg.quantity, isNull);
      expect(egg.needsConfirmation, isFalse);

      final tofu =
          result.recognizedIngredients.firstWhere((e) => e.name == '두부');
      expect(tofu.needsConfirmation, isTrue);
      expect(tofu.uncertaintyNote, contains('용기에 가려져'));
    });

    test('잘못된 JSON 형식 입력 시 크래시 대신 명시적 ScannerException을 던진다', () {
      expect(
        () => AiResponseValidator.validateAndParse('invalid json response'),
        throwsA(isA<ScannerException>()),
      );
    });
  });

  group('3. 요리 추천 엔진, 글로벌 카테고리, 메인 재료 선택 및 칼로리/영양소 계산 테스트', () {
    const engine = RecipeRecommendationEngine();
    final seasonings = {
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
    };

    final pantry = [
      const Ingredient(
        id: '1',
        name: '계란',
        category: IngredientCategory.eggDairy,
      ),
      const Ingredient(
        id: '2',
        name: '대파',
        category: IngredientCategory.vegetable,
      ),
      const Ingredient(
        id: '3',
        name: '밥',
        category: IngredientCategory.grain,
      ),
      const Ingredient(
        id: '4',
        name: '김치',
        category: IngredientCategory.processed,
      ),
      const Ingredient(
        id: '5',
        name: '두부',
        category: IngredientCategory.eggDairy,
      ),
    ];

    test('보유 재료만으로 가능한 요리와 1~2개 부족한 요리를 정확히 분리한다', () {
      final recommendations = engine.recommend(
        pantryIngredients: pantry,
        ownedSeasonings: seasonings,
        preferences: const UserPreferences(),
        allRecipes: VerifiedRecipesData.recipes,
      );

      final canMakeNow = recommendations
          .where((r) => r.tier == RecommendationTier.canMakeNow)
          .map((r) => r.recipe.id)
          .toList();

      expect(canMakeNow, contains('green_onion_egg_roll'));
      expect(canMakeNow, contains('soy_egg_butter_rice'));
      expect(canMakeNow, contains('japanese_agedashi_tofu_braise'));
      expect(canMakeNow, contains('chinese_egg_fried_rice'));
    });

    test('요리 카테고리(한식, 양식, 일식, 중식, 동남아) 필터링이 정확히 동작한다', () {
      final japaneseOnly = engine.recommend(
        pantryIngredients: pantry,
        ownedSeasonings: seasonings,
        preferences: const UserPreferences(),
        allRecipes: VerifiedRecipesData.recipes,
        selectedCategory: CuisineCategory.japanese,
      );

      expect(japaneseOnly, isNotEmpty);
      expect(japaneseOnly.every((r) => r.recipe.category == '일식'), isTrue);
    });

    test('특정 메인 재료(예: 두부)를 선택하면 해당 재료가 들어간 요리만 추천한다', () {
      final tofuMainRecipes = engine.recommend(
        pantryIngredients: pantry,
        ownedSeasonings: seasonings,
        preferences: const UserPreferences(),
        allRecipes: VerifiedRecipesData.recipes,
        selectedMainIngredient: '두부',
      );

      expect(tofuMainRecipes, isNotEmpty);
      expect(
        tofuMainRecipes.every((r) => r.usesSelectedMainIngredient),
        isTrue,
      );
      expect(
        tofuMainRecipes.map((r) => r.recipe.id),
        containsAll(['pork_kimchi_stew', 'japanese_agedashi_tofu_braise']),
      );
      expect(
        tofuMainRecipes.any((r) => r.recipe.id == 'soy_egg_butter_rice'),
        isFalse,
      );
    });

    test('알레르기 설정된 식재료(예: 난류/계란)가 포함된 레시피는 100% 제외한다', () {
      const eggAllergyPrefs = UserPreferences(
        allergens: {AllergenType.egg},
      );

      final filtered = engine.recommend(
        pantryIngredients: pantry,
        ownedSeasonings: seasonings,
        preferences: eggAllergyPrefs,
        allRecipes: VerifiedRecipesData.recipes,
      );

      expect(
        filtered.any((r) => r.recipe.id == 'green_onion_egg_roll'),
        isFalse,
      );
      expect(
        filtered.any((r) => r.recipe.id == 'soy_egg_butter_rice'),
        isFalse,
      );
    });

    test('인분 수 변경 시 재료 분량과 칼로리/영양소(탄·단·지·나트륨)가 비례하여 정확히 계산된다', () {
      const req = RecipeIngredientRequirement(
        name: '돼지고기',
        baseAmount: 200,
        unit: 'g',
      );
      expect(
        req.formatAmountForServings(baseServings: 2, targetServings: 3),
        '300g',
      );

      const nutrition = NutritionInfo(
        caloriesKcal: 400,
        carbsGrams: 50.0,
        proteinGrams: 20.0,
        fatGrams: 12.0,
        sodiumMg: 800,
      );
      final scaledFor3 = nutrition.scaleForServings(3);
      expect(scaledFor3.caloriesKcal, 1200);
      expect(scaledFor3.proteinGrams, 60.0);
      expect(scaledFor3.sodiumMg, 2400);
    });
  });

  group('4. 피드백 반영 사용자 흐름 위젯 통합 테스트', () {
    testWidgets(
      '갤러리 선택 제거 확인, 스캔 후 카테고리/메인 재료 필터, 설정창 알레르기 모달, 상세 영양소 계산까지 정상 동작한다',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        SharedPreferences.setMockInitialValues({});

        await tester.pumpWidget(
          const ProviderScope(
            child: FridgeChefApp(),
          ),
        );
        await tester.pumpAndSettle();

        // 1. 홈 화면에서 스캔 화면 진입 및 갤러리 버튼이 제거되었는지 확인
        await tester.tap(find.byKey(const Key('hero_start_scan_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('scan_camera_button')), findsOneWidget);
        expect(find.byKey(const Key('scan_gallery_button')), findsNothing);

        // 2. 샘플 스캔 실행 및 재료 확정
        final presetBtn = find.byKey(const Key('demo_preset_typical_button'));
        await tester.ensureVisible(presetBtn);
        await tester.tap(presetBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('confirm_scan_results_button')));
        await tester.pumpAndSettle();

        // 3. 맞춤 요리 추천 화면에서 카테고리 칩(한식, 양식, 일식, 중식, 동남아) 확인
        expect(find.byKey(const Key('cuisine_chip_korean')), findsOneWidget);
        expect(find.byKey(const Key('cuisine_chip_western')), findsOneWidget);
        expect(find.byKey(const Key('cuisine_chip_japanese')), findsOneWidget);
        expect(find.byKey(const Key('cuisine_chip_chinese')), findsOneWidget);
        expect(
          find.byKey(const Key('cuisine_chip_southeastAsian')),
          findsOneWidget,
        );

        // 4. 메인 재료 '두부' 칩 선택 -> 두부 메인 요리 필터링 확인
        final tofuChip = find.byKey(const Key('main_ingredient_chip_두부'));
        await tester.ensureVisible(tofuChip);
        await tester.tap(tofuChip);
        await tester.pumpAndSettle();

        expect(
          find.text('일식 달콤간장 두부 스테이크 (데리야끼 두부)'),
          findsOneWidget,
        );

        // 이미 선택된 '두부' 칩을 다시 탭하여 메인 재료 필터 해제(전체 재료로 복귀)
        await tester.tap(tofuChip);
        await tester.pumpAndSettle();

        // 5. 우측 상단 설정 아이콘 탭 -> 숨겨진 알레르기 필터 모달 시트 열림 확인
        await tester.tap(find.byKey(const Key('open_allergy_settings_button')));
        await tester.pumpAndSettle();
        expect(find.text('⚙️ 알레르기 및 제외 식재료 설정'), findsOneWidget);
        await tester.tap(find.text('설정 완료'));
        await tester.pumpAndSettle();

        // 6. 레시피 상세 화면 진입 -> 칼로리 및 영양소 계산 카드 및 인분 조절 연동 확인
        final eggRiceCard = find.byKey(
          const Key('recipe_card_soy_egg_butter_rice'),
        );
        await tester.ensureVisible(eggRiceCard);
        await tester.tap(eggRiceCard);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('nutrition_summary_card')), findsOneWidget);
        expect(find.text('칼로리 및 영양 성분 계산'), findsOneWidget);
        expect(find.text('465kcal'), findsOneWidget); // 1인분 기준 총 열량

        // 인분 + 버튼 탭 (1인분 -> 2인분) -> 총 열량이 930kcal로 실시간 계산됨
        final incBtn = find.byKey(const Key('servings_increase_button'));
        await tester.ensureVisible(incBtn);
        await tester.tap(incBtn);
        await tester.pumpAndSettle();
        expect(find.text('2인분'), findsOneWidget);
        expect(find.text('930kcal'), findsOneWidget);
      },
    );
  });
}
