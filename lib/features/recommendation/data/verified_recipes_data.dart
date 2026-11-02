import '../../preferences/domain/user_preferences.dart';
import '../domain/recipe.dart';

/// 글로벌 카테고리별 검증된 요리 레시피 시드 데이터베이스
/// - 한식: 만개의레시피 (10000recipe) 스타일
/// - 양식: BBC Good Food & Allrecipes 스타일
/// - 일식: Cookpad (쿡패드) 스타일
/// - 중식: 중화 가정식 표준
/// - 동남아: Allrecipes & 동남아 현지 스타일
/// 각 레시피는 1인분 기준 칼로리 및 영양소(탄·단·지·나트륨) 정보와 식품 안전 가이드를 포함합니다.
class VerifiedRecipesData {
  VerifiedRecipesData._();

  static const List<Recipe> recipes = [
    // ==================== 1. 한식 (만개의레시피) ====================
    Recipe(
      id: 'kimchi_fried_rice',
      title: '스팸 김치볶음밥과 반숙 계란프라이',
      subtitle: '익은 김치와 통조림 햄으로 실패 없이 만드는 국민 한그릇 요리',
      category: '한식',
      emoji: '🍳',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 540,
        carbsGrams: 68.0,
        proteinGrams: 18.5,
        fatGrams: 21.0,
        sodiumMg: 1180,
      ),
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
          instruction:
              '김치는 가위나 칼로 1cm 크기로 잘게 썰고, 대파는 송송 썰어 준비합니다. 통조림 햄도 한입 크기로 깍둑썰기합니다.',
          tip: '김치 국물이 있으면 2큰술 정도 따로 남겨두세요.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '달군 프라이팬에 식용유 2큰술을 두르고 중불에서 대파와 햄을 먼저 2분간 노릇하게 볶아 파기름을 냅니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '썰어둔 김치와 설탕 0.5큰술, 고춧가루 1큰술을 넣고 김치가 반투명해질 때까지 3분간 충분히 볶습니다.',
          tip: '신김치일수록 설탕을 약간 넣으면 신맛이 중화되고 감칠맛이 살아납니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 4,
          instruction:
              '팬 한쪽을 비워 간장 1큰술을 넣고 보글보글 끓어오르면 재료와 섞은 뒤, 밥을 넣고 주걱으로 세워가며 골고루 볶습니다.',
          tip: '찬밥을 사용하면 밥알이 뭉치지 않고 고슬고슬하게 볶아집니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 5,
          instruction:
              '불을 끄고 참기름 1큰술을 둘러 섞은 뒤, 별도로 구운 계란프라이를 올려 완성합니다.',
        ),
      ],
      safetyWarnings: [
        '계란 조리 시 껍질 표면의 살모넬라균 오염을 막기 위해 깨뜨린 후 반드시 손을 씻으세요.',
        '영유아, 임산부, 고령자가 섭취할 경우 계란 노른자까지 완전히 익혀(완숙) 조리하는 것이 안전합니다.',
      ],
      sourceName: '만개의레시피 (10000recipe) 인기 레시피 표준',
      sourceUrl: 'https://www.10000recipe.com',
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
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 420,
        carbsGrams: 14.0,
        proteinGrams: 28.0,
        fatGrams: 27.5,
        sodiumMg: 1350,
      ),
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
          instruction:
              '돼지고기와 김치는 한입 크기로 썰고, 두부는 도톰하게 1cm 두께로 썰어 준비합니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '냄비에 식용유 1큰술을 두르고 중불에서 돼지고기와 다진 마늘을 넣어 고기 겉면이 익을 때까지 3분간 볶습니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '김치와 설탕 0.5큰술, 고춧가루 1.5큰술을 넣고 김치가 나른해질 때까지 4분간 함께 볶습니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 4,
          instruction:
              '물 400ml(약 2컵)와 간장 1큰술을 붓고 중강불에서 10분간 푹 끓입니다.',
          timerMinutes: 10,
        ),
        CookingStep(
          stepNumber: 5,
          instruction:
              '두부와 어슷 썬 대파를 넣고 3분간 더 끓여 돼지고기 속까지 완전히 익힌 후 마무리합니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '생돼지고기를 다룬 칼과 도마는 교차 오염 방지를 위해 뜨거운 물과 세제로 세척한 후 채소나 두부를 손질하세요.',
        '돼지고기는 중심부 온도가 75°C 이상이 되도록 속까지 완전히 익혀 드세요.',
      ],
      sourceName: '만개의레시피 (10000recipe) 인기 레시피 표준',
      sourceUrl: 'https://www.10000recipe.com',
    ),
    Recipe(
      id: 'soy_egg_butter_rice',
      title: '초간단 간장계란밥',
      subtitle: '바쁜 날 5분 만에 완성하는 고소하고 든든한 한 끼',
      category: '한식',
      emoji: '🍚',
      cookingTimeMinutes: 5,
      difficulty: RecipeDifficulty.easy,
      baseServings: 1,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 465,
        carbsGrams: 65.0,
        proteinGrams: 16.0,
        fatGrams: 14.5,
        sodiumMg: 680,
      ),
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
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '따뜻한 밥 1공기를 넓은 그릇에 담습니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '프라이팬에 식용유를 두르고 계란 2개를 취향에 맞게(반숙 또는 완숙) 프라이합니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '밥 위에 계란프라이를 올리고 간장 1.5큰술과 참기름(또는 버터 1조각)을 넣어 맛있게 비벼 먹습니다.',
        ),
      ],
      safetyWarnings: [
        '날계란이나 덜 익힌 반숙 계란 섭취에 민감한 분은 노른자까지 충분히 익혀 조리하세요.',
      ],
      sourceName: '만개의레시피 (10000recipe) 자취요리 베스트',
      sourceUrl: 'https://www.10000recipe.com',
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
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 210,
        carbsGrams: 3.5,
        proteinGrams: 13.0,
        fatGrams: 15.5,
        sodiumMg: 390,
      ),
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
          instruction:
              '볼에 계란과 소금, 물 1큰술을 넣고 알끈이 풀리도록 고루 저은 뒤 다진 대파를 섞습니다.',
          tip: '물이나 우유를 1큰술 넣으면 식감이 훨씬 부드러워집니다.',
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '약불로 예열한 팬에 식용유를 얇게 코팅하고 계란물의 1/3만 부어 바닥이 익으면 끝에서부터 돌돌 말아줍니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 4,
          instruction:
              '말아둔 계란을 팬 끝으로 밀고 남은 계란물을 2번에 나누어 부어가며 이어서 말아 속까지 익힙니다.',
          timerMinutes: 4,
        ),
        CookingStep(
          stepNumber: 5,
          instruction:
              '불을 끄고 한 김 식힌 뒤 먹기 좋은 두께로 썰어 접시에 담습니다.',
        ),
      ],
      safetyWarnings: [
        '계란 껍질을 만진 손으로 다른 식재료를 만지지 마시고, 계란말이 중심부까지 열이 충분히 전달되도록 약불에서 익혀주세요.',
      ],
      sourceName: '만개의레시피 (10000recipe) 집밥 반찬 가이드',
      sourceUrl: 'https://www.10000recipe.com',
    ),

    // ==================== 2. 양식 (BBC Good Food & Allrecipes) ====================
    Recipe(
      id: 'french_omelette_western',
      title: '허브 어니언 프렌치 오믈렛',
      subtitle: 'BBC Good Food 스타일의 부드럽고 촉촉한 유럽식 브런치 오믈렛',
      category: '양식',
      emoji: '🧀',
      cookingTimeMinutes: 10,
      difficulty: RecipeDifficulty.easy,
      baseServings: 1,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 315,
        carbsGrams: 5.0,
        proteinGrams: 19.0,
        fatGrams: 24.0,
        sodiumMg: 420,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 3,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.3,
          unit: '개',
          substitutes: ['대파', '버섯', '토마토'],
        ),
        RecipeIngredientRequirement(
          name: '치즈',
          baseAmount: 1,
          unit: '장',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '소금',
          baseAmount: 0.2,
          unit: '작은술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '후추',
          baseAmount: 0.1,
          unit: '작은술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 1,
          unit: '큰술',
          substitutes: ['버터'],
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '양파(또는 대파)를 잘게 다지고 계란 3개를 볼에 풀어 소금, 후추로 간을 합니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '프라이팬에 버터(또는 식용유)를 두르고 다진 양파를 약불에서 투명해질 때까지 2분간 볶습니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '계란물을 붓고 젓가락으로 빠르게 원을 그리며 스크램블하듯 익히다가, 70%쯤 익었을 때 반달 모양으로 접어 여열로 마무리합니다.',
          tip: '치즈가 있다면 접기 직전 가운데에 넣어 녹여 주세요.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '신선한 냉장 계란을 사용하고, 면역력이 약한 분은 중심부까지 충분히 가열해 드세요.',
      ],
      sourceName: 'BBC Good Food & Allrecipes Classic Omelette',
      sourceUrl: 'https://www.bbcgoodfood.com',
    ),
    Recipe(
      id: 'garlic_butter_shrimp_scampi',
      title: '갈릭 버터 쉬림프 스캠피',
      subtitle: 'Allrecipes 인기 미국식 레스토랑 스타일 마늘 새우 요리',
      category: '양식',
      emoji: '🍤',
      cookingTimeMinutes: 12,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 290,
        carbsGrams: 6.5,
        proteinGrams: 23.0,
        fatGrams: 18.5,
        sodiumMg: 540,
      ),
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
          name: '소금',
          baseAmount: 0.3,
          unit: '작은술',
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
          instruction: '새우는 찬물에 씻어 키친타월로 물기를 완전히 제거한 뒤 소금, 후추로 밑간합니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '팬에 오일(또는 버터)과 마늘을 넣고 약불에서 1분간 향을 낸 뒤 새우를 넣고 중불에서 앞뒤로 노릇하게 굽습니다.',
          timerMinutes: 4,
        ),
      ],
      safetyWarnings: [
        '새우 등 해산물은 속살이 불투명한 흰색이 될 때까지 완전히 익혀 드세요.',
      ],
      sourceName: 'Allrecipes (US) Garlic Shrimp Scampi',
      sourceUrl: 'https://www.allrecipes.com',
    ),

    // ==================== 3. 일식 (Cookpad 쿡패드) ====================
    Recipe(
      id: 'japanese_butadon_cookpad',
      title: '훗카이도식 간장 돼지고기 덮밥 (부타동)',
      subtitle: 'Cookpad(쿡패드) 인기 단짠단짠 간장 타레 소스 덮밥',
      category: '일식',
      emoji: '🍱',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 580,
        carbsGrams: 72.0,
        proteinGrams: 26.0,
        fatGrams: 19.5,
        sodiumMg: 980,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '돼지고기',
          baseAmount: 200,
          unit: 'g',
          substitutes: ['삼겹살', '스팸/통조림햄'],
        ),
        RecipeIngredientRequirement(
          name: '밥',
          baseAmount: 2,
          unit: '공기',
        ),
        RecipeIngredientRequirement(
          name: '양파',
          baseAmount: 0.5,
          unit: '개',
          substitutes: ['대파'],
        ),
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 2,
          unit: '개',
          isOptional: true,
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 3,
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
          instruction: '간장 3큰술, 설탕 1.5큰술, 물 3큰술, 다진 마늘 0.5큰술을 섞어 일식 덮밥 타레 소스를 만듭니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '팬에 식용유를 두르고 채 썬 양파와 돼지고기를 중강불에서 앞뒤로 노릇하게 익힙니다.',
          timerMinutes: 5,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '타레 소스를 붓고 고기에 윤기가 돌 때까지 2분간 졸인 뒤 따뜻한 밥 위에 얹어 완성합니다.',
          timerMinutes: 2,
        ),
      ],
      safetyWarnings: [
        '돼지고기는 붉은 기가 남지 않도록 중심부까지 완전히 가열해 조리하세요.',
      ],
      sourceName: 'Cookpad (쿡패드 일본 가정식 베스트)',
      sourceUrl: 'https://cookpad.com',
    ),
    Recipe(
      id: 'japanese_agedashi_tofu_braise',
      title: '일식 달콤간장 두부 스테이크 (데리야끼 두부)',
      subtitle: 'Cookpad 스타일로 두부를 바삭하게 구워 간장 소스에 졸인 일품 요리',
      category: '일식',
      emoji: '🍱',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 265,
        carbsGrams: 12.0,
        proteinGrams: 16.5,
        fatGrams: 16.0,
        sodiumMg: 720,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '두부',
          baseAmount: 1,
          unit: '모',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          substitutes: ['양파'],
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 2.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
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
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '두부는 물기를 꼼꼼히 닦아낸 뒤 큼직하게 썰어 팬에 노릇하게 앞뒤로 굽습니다.',
          timerMinutes: 5,
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '간장 2.5큰술, 설탕 1큰술, 물 2큰술을 넣고 윤기 나게 졸인 뒤 송송 썬 대파를 듬뿍 올립니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '두부의 물기를 제거한 뒤 구워야 기름이 튀어 화상을 입는 것을 방지할 수 있습니다.',
      ],
      sourceName: 'Cookpad (쿡패드 두부 요리 인기선)',
      sourceUrl: 'https://cookpad.com',
    ),

    // ==================== 4. 중식 ====================
    Recipe(
      id: 'chinese_egg_fried_rice',
      title: '중화풍 황금 파기름 계란볶음밥',
      subtitle: '대파와 계란, 밥만으로 중식당 불맛을 내는 고슬고슬 볶음밥',
      category: '중식',
      emoji: '🥟',
      cookingTimeMinutes: 10,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 490,
        carbsGrams: 66.0,
        proteinGrams: 15.0,
        fatGrams: 17.5,
        sodiumMg: 740,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '밥',
          baseAmount: 2,
          unit: '공기',
        ),
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 3,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 1,
          unit: '대',
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 1.5,
          unit: '큰술',
          substitutes: ['굴소스'],
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '소금',
          baseAmount: 0.3,
          unit: '작은술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '식용유',
          baseAmount: 3,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '달군 팬에 식용유 3큰술과 송송 썬 대파를 넣고 중불에서 파기름을 충분히 냅니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '계란 3개를 풀어 넣고 빠르게 스크램블한 뒤 팬 가장자리에 간장 1.5큰술을 태우듯 둘러 불향을 냅니다.',
          timerMinutes: 2,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '밥을 넣고 센불에서 밥알이 코팅되도록 3분간 볶아 완성합니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '센불에서 기름을 다룰 때 손잡이를 꼭 잡고 화상에 주의하세요.',
      ],
      sourceName: '만개의레시피 & 중화가정식 표준 가이드',
      sourceUrl: 'https://www.10000recipe.com',
    ),
    Recipe(
      id: 'chinese_mapo_tofu_style',
      title: '매콤 중화풍 두부 덮밥 (가정식 마파두부)',
      subtitle: '두부와 다진 고기(또는 햄), 대파로 만드는 얼큰하고 부드러운 중식 덮밥',
      category: '중식',
      emoji: '🥟',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.medium,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 450,
        carbsGrams: 42.0,
        proteinGrams: 22.0,
        fatGrams: 21.0,
        sodiumMg: 1120,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '두부',
          baseAmount: 1,
          unit: '모',
        ),
        RecipeIngredientRequirement(
          name: '돼지고기',
          baseAmount: 100,
          unit: 'g',
          substitutes: ['스팸/통조림햄', '소고기', '계란'],
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
        ),
        RecipeIngredientRequirement(
          name: '된장',
          baseAmount: 1,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고추장',
          baseAmount: 1,
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
          name: '간장',
          baseAmount: 1,
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
          instruction: '두부는 1.5cm 크기로 깍둑썰기하고, 대파와 고기(또는 햄)는 잘게 썹니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '팬에 식용유 2큰술을 두르고 대파, 마늘, 고춧가루 1큰술을 약불에 볶아 고추기름을 낸 뒤 고기를 넣고 익힙니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '물 200ml와 된장 1큰술, 고추장 1큰술, 간장 1큰술을 풀고 두부를 넣어 5분간 졸인 뒤 참기름으로 마무리합니다.',
          timerMinutes: 5,
        ),
      ],
      safetyWarnings: [
        '다진 고기는 속까지 완전히 익히고, 뜨거운 두부는 내부 열기가 오래 유지되므로 섭취 시 화상에 주의하세요.',
      ],
      sourceName: '만개의레시피 중화요리 인기 가이드',
      sourceUrl: 'https://www.10000recipe.com',
    ),

    // ==================== 5. 동남아 (Allrecipes Asian) ====================
    Recipe(
      id: 'southeast_asian_nasi_goreng',
      title: '동남아풍 스파이시 나시고랭 (인도네시아 볶음밥)',
      subtitle: '간장과 마늘, 고추장(삼발 대체), 계란프라이로 이국적인 풍미를 살린 볶음밥',
      category: '동남아',
      emoji: '🍜',
      cookingTimeMinutes: 15,
      difficulty: RecipeDifficulty.easy,
      baseServings: 2,
      nutritionPerServing: NutritionInfo(
        caloriesKcal: 520,
        carbsGrams: 67.0,
        proteinGrams: 19.0,
        fatGrams: 18.5,
        sodiumMg: 1050,
      ),
      ingredients: [
        RecipeIngredientRequirement(
          name: '밥',
          baseAmount: 2,
          unit: '공기',
        ),
        RecipeIngredientRequirement(
          name: '계란',
          baseAmount: 2,
          unit: '개',
        ),
        RecipeIngredientRequirement(
          name: '대파',
          baseAmount: 0.5,
          unit: '대',
          substitutes: ['양파'],
        ),
        RecipeIngredientRequirement(
          name: '새우',
          baseAmount: 8,
          unit: '마리',
          substitutes: ['스팸/통조림햄', '돼지고기', '닭고기'],
        ),
        RecipeIngredientRequirement(
          name: '간장',
          baseAmount: 2,
          unit: '큰술',
          substitutes: ['굴소스'],
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '고추장',
          baseAmount: 0.5,
          unit: '큰술',
          isSeasoning: true,
        ),
        RecipeIngredientRequirement(
          name: '설탕',
          baseAmount: 1,
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
          baseAmount: 2,
          unit: '큰술',
          isSeasoning: true,
        ),
      ],
      steps: [
        CookingStep(
          stepNumber: 1,
          instruction: '간장 2큰술, 설탕 1큰술, 고추장 0.5큰술을 섞어 동남아풍 달콤매콤 볶음 소스를 만듭니다.',
        ),
        CookingStep(
          stepNumber: 2,
          instruction:
              '달군 팬에 식용유를 두르고 마늘과 대파, 새우(또는 햄/고기)를 넣어 완전히 익을 때까지 볶습니다.',
          timerMinutes: 3,
        ),
        CookingStep(
          stepNumber: 3,
          instruction:
              '밥과 소스를 넣고 센불에서 3분간 볶은 뒤 반숙 또는 완숙 계란프라이를 얹어 완성합니다.',
          timerMinutes: 3,
        ),
      ],
      safetyWarnings: [
        '새우나 육류를 사용할 경우 중심부까지 완전히 가열하여 조리하세요.',
      ],
      sourceName: 'Allrecipes Southeast Asian Street Food Guide',
      sourceUrl: 'https://www.allrecipes.com',
    ),
  ];
}
