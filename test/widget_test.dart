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

      // 락앤락 용기는 제외되고, 달걀+계란은 '계란' 6개로 병합되어 총 2개여야 함
      expect(normalized.length, 2);
      // 확인이 필요한 '두부'가 첫 번째로 정렬됨
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
      // AI가 임의로 넣은 quantity(99)는 폐기되어야 함
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

  group('3. 요리 추천 엔진 및 알레르기 엄격 필터링 테스트', () {
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

    test('보유 재료만으로 가능한 요리와 1~2개 부족한 요리를 정확히 분리한다', () {
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
      ];

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
      final almostReady = recommendations
          .where((r) => r.tier == RecommendationTier.almostReady)
          .toList();

      // 계란, 대파, 밥이 있으므로 '대파 계란말이'와 '간장계란밥'은 지금 바로 가능!
      expect(canMakeNow, contains('green_onion_egg_roll'));
      expect(canMakeNow, contains('soy_egg_butter_rice'));

      // 김치, 밥, 대파, 계란이 있고 '스팸/통조림햄' 1개만 부족하므로 '스팸 김치볶음밥'은 조금만 추가하면 가능!
      final kimchiFriedRice = almostReady.firstWhere(
        (r) => r.recipe.id == 'kimchi_fried_rice',
      );
      expect(kimchiFriedRice.missingCoreIngredients, ['스팸/통조림햄']);
      // 수량이 입력되지 않았으므로 불확실성 안내 플래그가 true여야 함
      expect(kimchiFriedRice.hasUncertainQuantities, isTrue);
    });

    test('알레르기 설정된 식재료(예: 난류/계란, 돼지고기)가 포함된 레시피는 100% 제외한다', () {
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
      ];

      final eggAllergyPrefs = const UserPreferences(
        allergens: {AllergenType.egg},
      );

      final filtered = engine.recommend(
        pantryIngredients: pantry,
        ownedSeasonings: seasonings,
        preferences: eggAllergyPrefs,
        allRecipes: VerifiedRecipesData.recipes,
      );

      // 계란이 들어가는 계란말이, 간장계란밥, 김치볶음밥은 모두 제외되어야 함
      expect(
        filtered.any((r) => r.recipe.id == 'green_onion_egg_roll'),
        isFalse,
      );
      expect(
        filtered.any((r) => r.recipe.id == 'soy_egg_butter_rice'),
        isFalse,
      );
    });

    test('인분 수 변경 시 재료 분량이 비례하여 정확히 계산된다', () {
      const req = RecipeIngredientRequirement(
        name: '돼지고기',
        baseAmount: 200,
        unit: 'g',
      );
      expect(
        req.formatAmountForServings(baseServings: 2, targetServings: 1),
        '100g',
      );
      expect(
        req.formatAmountForServings(baseServings: 2, targetServings: 3),
        '300g',
      );
    });
  });

  group('4. 핵심 사용자 흐름 위젯 통합 테스트 (스캔 -> 검수/수정 -> 요리 추천 -> 상세)', () {
    testWidgets(
      '홈 화면에서 냉장고 스캔 샘플 실행, 불확실 재료 확인 후 추천 요리 및 상세 조리법까지 정상 동작한다',
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

        // 1. 홈 화면에 기본 보유 재료(계란, 김치, 대파, 밥)가 표시되는지 확인
        expect(find.text('🥬 냉장고 셰프 AI'), findsOneWidget);
        expect(find.text('계란'), findsOneWidget);

        // 2. [사진으로 재료 인식] 버튼을 눌러 스캔 화면 진입
        await tester.tap(find.byKey(const Key('hero_start_scan_button')));
        await tester.pumpAndSettle();
        expect(find.text('AI 냉장고 식재료 스캔'), findsOneWidget);

        // 3. 오류 시뮬레이션 버튼이 화면 아래에 있을 수 있으므로 ensureVisible 후 탭
        final errorBtn = find.byKey(const Key('demo_preset_error_button'));
        await tester.ensureVisible(errorBtn);
        await tester.tap(errorBtn);
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('scan_error_fallback_card')), findsOneWidget);

        // 4. [다시 시도] 버튼 ensureVisible 후 탭 -> 정상 인식 결과 검수 리스트 표시 검증
        final retryBtn = find.byKey(const Key('retry_scan_button'));
        await tester.ensureVisible(retryBtn);
        await tester.tap(retryBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pumpAndSettle();

        // 불확실한 항목(두부, 스팸/통조림햄)에 '⚠️ 확인 필요' 배지가 표시됨
        expect(find.text('⚠️ 확인 필요'), findsWidgets);

        // 5. [재료 확정 및 요리 추천받기] 버튼 탭 -> 자동으로 맞춤 요리 추천 탭으로 전환됨
        await tester.tap(find.byKey(const Key('confirm_scan_results_button')));
        await tester.pumpAndSettle();

        expect(find.text('🍳 맞춤 요리 추천'), findsOneWidget);
        expect(find.text('초간단 간장계란밥'), findsOneWidget);

        // 6. 추천 요리 카드('초간단 간장계란밥')를 탭하여 상세 레시피 화면 진입 및 인분 조절 검증
        final eggRiceCard = find.byKey(
          const Key('recipe_card_soy_egg_butter_rice'),
        );
        await tester.ensureVisible(eggRiceCard);
        await tester.tap(eggRiceCard);
        await tester.pumpAndSettle();

        expect(find.text('단계별 조리 방법 (초보자 가이드)'), findsOneWidget);
        expect(find.text('식품 안전 및 조리 주의사항'), findsOneWidget);
        expect(find.byKey(const Key('servings_count_text')), findsOneWidget);
        expect(find.text('2인분'), findsOneWidget);

        // 인분 + 버튼 탭 -> 3인분으로 변경되고 밥 분량이 2공기 -> 3공기로 변경됨
        final incBtn = find.byKey(const Key('servings_increase_button'));
        await tester.ensureVisible(incBtn);
        await tester.tap(incBtn);
        await tester.pumpAndSettle();
        expect(find.text('3인분'), findsOneWidget);
        expect(find.text('3공기'), findsOneWidget);
      },
    );
  });
}
