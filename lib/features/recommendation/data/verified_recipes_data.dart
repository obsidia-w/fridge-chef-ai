import '../../preferences/domain/user_preferences.dart';
import '../domain/recipe.dart';

/// 검증된 한국인 일상 요리 레시피 시드 데이터베이스
/// 생고기, 해산물, 계란 등 식품 안전 지침과 초보자용 단계별 가이드를 포함합니다.
class VerifiedRecipesData {
  VerifiedRecipesData._();

  static const List<Recipe> recipes = [
    Recipe(
      id: 'kimchi_fried_rice',
      title: '스팸 김치볶음밥과 반숙 계란프라이',
      subtitle: '익은 김치와 통조림 햄으로 실패 없이 만드는 국민 한그릇 요리',
      category: '한식',
      emoji: '🍳',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '김치',
          baseAmount: 1.5,
          unit: '컵',
        ),
        RecipeIngredientRequirement(
          name: '밥',
          baseAmount: 2,
          unit: '공기',
        ),
        RecipeIngredientRequirement(
          name: '스팸/통조림햄',
          baseAmount: 150,
          unit: 'g',
          substitutes: ['소시지', '베이컨', '돼지고기', '참치통조림'],
        ),
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 2,
          unit: '개',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          substitutes: ['양파'],
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고춧가루',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '참기름',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '김치는 가위나 칼로 1cm 크기로 잘게 썰고, 대파는 송송 썰어 준비합니다. 통조림 햄도 한입 크기로 깍둑썰기합니다.',
          tip: '김치 국물이 있으면 2큰술 정도 따로 남겨두세요.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '달군 프라이팬에 식용유 2큰술을 두르고 중불에서 대파와 햄을 먼저 2분간 노릇하게 볶아 파기름을 냅니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '썰어둔 김치와 설탕 0.5큰술, 고춧가루 1큰술을 넣고 김치가 반투명해질 때까지 3분간 충분히 볶습니다.',
          tip: '신김치일수록 설탕을 약간 넣으면 신맛이 중화되고 감칠맛이 살아납니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '팬 한쪽을 비워 간장 1큰술을 넣고 보글보글 끓어오르면 재료와 섞은 뒤, 밥을 넣고 주걱으로 세워가며 골고루 볶습니다.',
          tip: '찬밥을 사용하면 밥알이 뭉치지 않고 고슬고슬하게 볶아집니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 5,
          instruction: '불을 끄고 참기름 1큰술을 둘러 섞은 뒤, 별도로 구운 계란프라이를 올려 완성합니다.',
        ),
      ],
      safetyWarnings: [
        '계란 조리 시 껍질 표면의 살모넬라균 오염을 막기 위해 깨뜨린 후 반드시 손을 씻으세요.',
        '영유아, 임산부, 고령자가 섭취할 경우 계란 노른자까지 완전히 익혀(완숙) 조리하는 것이 안전합니다.',
      ],
      sourceName: '냉장고 셰프 검증 한식 표준 레시피',
    ),
    Recipe(
      id: 'pork_kimchi_stew',
      title: '돼지고기 두부 김치찌개',
      subtitle: '깊고 진한 국물 맛이 일품인 한국인의 소울 푸드',
      category: '한식',
      emoji: '🍲',
      cookingTimeMinutes: 25,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '김치',
          baseAmount: 2,
          unit: '컵',
        ),
        RecipeIngredientRequirement(
          name: '돼지고기',
          baseAmount: 200,
          unit: 'g',
          substitutes: ['삼겹살', '스팸/통조림햄', '참치통조림'],
        ),
        RecipeIngredientRequirement(
          name: '두부',
          baseAmount: 0.5,
          unit: '모',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          substitutes: ['양파'],
        ),
        RecipeIngredientRequirement(
          name: '마늘',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고춧가루',
          baseAmount: 1.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '돼지고기와 김치는 한입 크기로 썰고, 두부는 도톰하게 1cm 두께로 썰어 준비합니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '냄비에 식용유 1큰술을 두르고 중불에서 돼지고기와 다진 마늘을 넣어 고기 겉면이 익을 때까지 3분간 볶습니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '김치와 설탕 0.5큰술, 고춧가루 1.5큰술을 넣고 김치가 나른해질 때까지 4분간 함께 볶습니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '물 400ml(약 2컵)와 간장 1큰술을 붓고 중강불에서 10분간 푹 끓입니다.',
          timerMinutes: 10,
        ),
        CookingStep(
          stepNumber: 5,
          instruction: '두부와 어슷 썬 대파를 넣고 3분간 더 끓여 돼지고기 속까지 완전히 익힌 후 마무리합니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '생돼지고기를 다룬 칼과 도마는 교차 오염 방지를 위해 뜨거운 물과 세제로 세척한 후 채소나 두부를 손질하세요.',
        '돼지고기는 중심부 온도가 75°C 이상이 되도록 속까지 완전히 익혀 드세요.',
      ],
      sourceName: '냉장고 셰프 검증 한식 표준 레시피',
    ),
    Recipe(
      id: 'green_onion_egg_roll',
      title: '폭신폭신 대파 계란말이',
      subtitle: '계란과 대파만으로 10분 만에 완성하는 밥도둑 반찬',
      category: '한식',
      emoji: '🥚',
      cookingTimeMinutes: 10,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 4,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          substitutes: ['양파', '당근', '치즈', '김'],
        ),
        RecipeIngredientRequirement(
          name: '소금',
          baseAmount: 0.3,
          unit: '작은술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '대파는 계란이 찢어지지 않도록 최대한 곱게 다집니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '볼에 계란과 소금, 물 1큰술을 넣고 알끈이 풀리도록 고루 저은 뒤 다진 대파를 섞습니다.',
          tip: '물이나 우유를 1큰술 넣으면 식감이 훨씬 부드러워집니다.',
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '약불로 예열한 팬에 식용유를 얇게 코팅하고 계란물의 1/3만 부어 바닥이 익으면 끝에서부터 돌돌 말아줍니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '말아둔 계란을 팬 끝으로 밀고 남은 계란물을 2번에 나누어 부어가며 이어서 말아 속까지 익힙니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 5,
          instruction: '불을 끄고 한 김 식힌 뒤 먹기 좋은 두께로 썰어 접시에 담습니다.',
          tip: '조금 식힌 뒤 썰어야 모양이 흐트러지지 않습니다.',
        ),
      ],
      safetyWarnings: [
        '계란 껍질을 만진 손으로 다른 식재료를 만지지 마시고, 계란말이 중심부까지 열이 충분히 전달되도록 약불에서 익혀주세요.',
      ],
      sourceName: '냉장고 셰프 검증 자취요리 레시피',
    ),
    Recipe(
      id: 'braised_tofu',
      title: '매콤 짭조름 밥도둑 두부조림',
      subtitle: '겉은 쫄깃하고 속은 촉촉한 양념 베인 두부 반찬',
      category: '한식',
      emoji: '🥘',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '두부',
          baseAmount: 1,
          unit: '모',
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.5,
          unit: '개',
          substitutes: ['대파', '버섯'],
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 3,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고춧가루',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '마늘',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '참기름',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '두부는 1cm 두께로 썰어 키친타월로 물기를 가볍게 닦아내고, 양파와 대파는 채 썰어 준비합니다.',
          tip: '물기를 닦아야 기름이 튀지 않고 두부가 단단하게 구워집니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '간장 3큰술, 고춧가루 1큰술, 설탕 0.5큰술, 다진 마늘 0.5큰술, 물 100ml(반 컵)를 섞어 양념장을 만듭니다.',
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '달군 팬에 식용유를 두르고 중불에서 두부 앞뒤를 각각 2분씩 노릇하게 부쳐냅니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '두부 위에 썬 양파와 대파를 올리고 양념장을 골고루 부은 뒤 중약불에서 5분간 국물을 끼얹어가며 졸입니다.',
          timerMinutes: 5,
        ),
        CookingStep(
          stepNumber: 5,
          instruction: '국물이 자작해지면 참기름을 두르고 불을 끕니다.',
        ),
      ],
      safetyWarnings: [
        '물기가 있는 두부를 뜨거운 기름에 넣으면 기름이 튈 수 있으니 키친타월로 물기를 제거한 후 중불에서 조리하세요.',
      ],
      sourceName: '냉장고 셰프 검증 한식 표준 레시피',
    ),
    Recipe(
      id: 'soy_egg_butter_rice',
      title: '초간단 간장계란밥',
      subtitle: '바쁜 날 5분 만에 완성하는 고소하고 든든한 한 끼',
      category: '자취요리',
      emoji: '🍚',
      cookingTimeMinutes: 5,
      difficulty: RecipeDifficulty.easy,
      baseServings: 1,
      ingredients: [
        RecipeIngredientRequirement(
          name: '밥',
          baseAmount: 1,
          unit: '공기',
        ),
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 2,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 1.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '참기름',
          baseAmount: 1,
          unit: '큰술',
          substitutes: ['버터'],
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '김',
          baseAmount: 1,
          unit: '봉',
          isOptional: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '따뜻한 밥 1공기를 넓은 그릇에 담습니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '프라이팬에 식용유를 두르고 계란 2개를 취향에 맞게(반숙 또는 완숙) 프라이합니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '밥 위에 계란프라이를 올리고 간장 1.5큰술과 참기름(또는 버터 1조각)을 넣어 맛있게 비벼 먹습니다.',
        ),
      ],
      safetyWarnings: [
        '날계란이나 덜 익힌 반숙 계란 섭취에 민감한 분은 노른자까지 충분히 익혀 조리하세요.',
      ],
      sourceName: '냉장고 셰프 검증 자취요리 레시피',
    ),
    Recipe(
      id: 'doenjang_jjigae',
      title: '구수한 애호박 감자 된장찌개',
      subtitle: '집에 있는 채소와 두부로 끓이는 속 편한 집밥 국물 요리',
      category: '한식',
      emoji: '🥘',
      cookingTimeMinutes: 20,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '두부',
          baseAmount: 0.5,
          unit: '모',
        ),
        RecipeIngredientRequirement(
          name: '감자',
          baseAmount: 1,
          unit: '개',
          substitutes: ['무', '버섯'],
        ),
        RecipeIngredientRequirement(
          name: '호박',
          baseAmount: 0.3,
          unit: '개',
          substitutes: ['양파', '버섯'],
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.5,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '된장',
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '마늘',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고춧가루',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '감자, 호박, 양파, 두부를 사방 1.5cm 크기로 깍둑썰기합니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '냄비에 물 450ml를 붓고 된장 2큰술을 체에 거르거나 잘 풀어준 뒤 가장 단단한 감자를 먼저 넣고 끓입니다.',
          timerMinutes: 5,
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '감자가 반쯤 익으면 양파, 호박, 다진 마늘, 고춧가루를 넣고 5분간 더 끓입니다.',
          timerMinutes: 5,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '마지막으로 두부와 대파를 넣고 2분간 한소끔 끓여 완성합니다.',
          timerMinutes: 2,
        ),
      ],
      safetyWarnings: [
        '감자 싹이 난 부분이나 초록색으로 변한 껍질에는 독성 성분(솔라닌)이 있으므로 반드시 깊게 도려내고 사용하세요.',
      ],
      sourceName: '냉장고 셰프 검증 한식 표준 레시피',
    ),
    Recipe(
      id: 'spicy_stir_fried_pork',
      title: '매콤달콤 기사식당 제육볶음',
      subtitle: '불향 가득 양념에 양파와 대파를 듬뿍 넣은 대표 고기 반찬',
      category: '한식',
      emoji: '🥩',
      cookingTimeMinutes: 20,
      difficulty: RecipeDifficulty.medium,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '돼지고기',
          baseAmount: 300,
          unit: 'g',
          substitutes: ['삼겹살'],
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.5,
          unit: '개',
          substitutes: ['양배추'],
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 1,
          unit: '대',
        ),
        RecipeIngredientRequirement(
          name: '고추장',
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고춧가루',
          baseAmount: 1.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 1.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '마늘',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '참기름',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '돼지고기는 한입 크기로 썰어 설탕 1.5큰술, 간장 2큰술, 고추장 2큰술, 고춧가루 1.5큰술, 다진 마늘 1큰술과 함께 버무려 5분간 재워둡니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '양파는 굵게 채 썰고 대파는 큼직하게 어슷 썰어 준비합니다.',
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '달군 팬에 식용유 1큰술을 두르고 중강불에서 양념한 돼지고기를 펼쳐 넣은 뒤 6분간 충분히 볶습니다.',
          timerMinutes: 6,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '고기가 80% 이상 익으면 양파와 대파를 넣고 숨이 살짝 죽을 때까지 3분간 빠르게 볶은 뒤 참기름을 둘러 완성합니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '생돼지고기는 중심부까지 붉은 기가 없도록 완전히 익혀 조리해야 식중독 및 기생충 감염을 예방할 수 있습니다.',
        '생고기를 담았던 그릇이나 집게는 익은 고기를 담을 때 재사용하지 마세요.',
      ],
      sourceName: '냉장고 셰프 검증 한식 표준 레시피',
    ),
    Recipe(
      id: 'garlic_shrimp_stir_fry',
      title: '마늘 간장 버터 새우구이(또는 새우볶음)',
      subtitle: '새우와 마늘의 풍미가 어우러진 10분 일품 요리',
      category: '일품요리',
      emoji: '🍤',
      cookingTimeMinutes: 12,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      ingredients: [
        RecipeIngredientRequirement(
          name: '새우',
          baseAmount: 12,
          unit: '마리',
        ),
        RecipeIngredientRequirement(
          name: '마늘',
          baseAmount: 1.5,
          unit: '큰술',
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.5,
          unit: '개',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 2,
          unit: '큰술',
          substitutes: ['버터'],
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 1,
          unit: '큰술',
          substitutes: ['굴소스'],
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '후추',
          baseAmount: 0.2,
          unit: '작은술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '새우는 흐르는 찬물에 씻어 키친타월로 물기를 완전히 제거합니다(냉동 새우는 찬물에 해동 후 물기 제거).',
        ),
        CookingStep(
          stepNumber: 2,
          instruction: '팬에 식용유(또는 버터)와 마늘을 넣고 약불에서 마늘 향이 올라올 때까지 1분간 볶습니다.',
          timerMinutes: 1,
        ),
        CookingStep(
          stepNumber: 3,
          instruction: '새우를 넣고 중불에서 앞뒤가 붉고 불투명해질 때까지 4분간 굽습니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 4,
          instruction: '간장 1큰술, 설탕 0.5큰술, 후추를 넣고 1분간 빠르게 코팅하듯 볶아 완성합니다.',
          timerMinutes: 1,
        ),
      ],
      safetyWarnings: [
        '새우 등 해산물은 상온에 방치하면 빠르게 변질되므로 해동 즉시 조리하고, 속살이 불투명한 흰색이 될 때까지 완전히 가열하세요.',
        '갑각류 알레르기가 있는 분은 섭취를 피해야 합니다.',
      ],
      sourceName: '냉장고 셰프 검증 일품요리 레시피',
    ),
  ];
}
