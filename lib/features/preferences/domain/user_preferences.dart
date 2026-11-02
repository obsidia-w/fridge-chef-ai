/// 알레르기 및 기피 식재료 카테고리
enum AllergenType {
  egg('난류(계란)', ['계란', '달걀', '메추리알', '마요네즈']),
  dairy('우유/유제품', ['우유', '치즈', '버터', '생크림', '요거트']),
  pork('돼지고기', ['돼지고기', '삼겹살', '베이컨', '스팸/통조림햄', '소시지']),
  beef('소고기', ['소고기', '쇠고기', '우육']),
  chicken('닭고기', ['닭고기', '닭가슴살']),
  shellfish('갑각류(새우/게)', ['새우', '게', '새우젓', '굴소스', '피시소스']),
  seafood('어패류/해산물', ['고등어', '오징어', '멸치', '어묵', '참치통조림', '조개', '굴', '가쓰오부시']),
  soy('대두(콩/두부)', ['두부', '콩나물', '된장', '간장']),
  wheat('밀(면/빵류)', ['라면', '소면', '파스타면', '우동면', '쌀국수면', '식빵', '부침가루', '밀가루']);

  final String label;
  final List<String> triggerIngredients;
  const AllergenType(this.label, this.triggerIngredients);
}

/// 요리 난이도 (레시피 자체 메타데이터용)
enum RecipeDifficulty {
  easy('쉬움', 1),
  medium('보통', 2),
  hard('어려움', 3);

  final String label;
  final int level;
  const RecipeDifficulty(this.label, this.level);
}

/// 글로벌 요리 카테고리 (피드백 반영: 한식, 양식, 일식, 중식, 동남아 등)
enum CuisineCategory {
  all('전체', '🍽️', '전체 플랫폼'),
  korean('한식', '🍚', '만개의레시피 (10000recipe)'),
  western('양식', '🍝', 'BBC Good Food & Allrecipes'),
  japanese('일식', '🍱', 'Cookpad (쿡패드)'),
  chinese('중식', '🥟', '만개의레시피 & 중화요리 표준'),
  southeastAsian('동남아', '🍜', 'Allrecipes & 동남아 현지 레시피');

  final String label;
  final String emoji;
  final String primarySourceSite;
  const CuisineCategory(this.label, this.emoji, this.primarySourceSite);

  static CuisineCategory fromLabel(String value) {
    for (final c in CuisineCategory.values) {
      if (c.label == value || c.name == value) {
        return c;
      }
    }
    return CuisineCategory.korean;
  }
}

/// 개인화 설정 엔티티 (피드백 반영: 조리시간, 난이도, 인분 수 설정 제거 & 알레르기 필터만 깔끔하게 유지)
class UserPreferences {
  final Set<AllergenType> allergens;
  final List<String> dislikedIngredients;

  const UserPreferences({
    this.allergens = const {},
    this.dislikedIngredients = const [],
  });

  /// 특정 식재료가 사용자의 알레르기 또는 기피 식재료에 해당하는지 엄격히 검사
  bool isRestrictedIngredient(String ingredientName) {
    final normalized = ingredientName.trim();
    for (final disliked in dislikedIngredients) {
      if (normalized.contains(disliked.trim()) ||
          disliked.trim().contains(normalized)) {
        return true;
      }
    }
    for (final allergen in allergens) {
      for (final trigger in allergen.triggerIngredients) {
        if (normalized == trigger || normalized.contains(trigger)) {
          return true;
        }
      }
    }
    return false;
  }

  UserPreferences copyWith({
    Set<AllergenType>? allergens,
    List<String>? dislikedIngredients,
  }) {
    return UserPreferences(
      allergens: allergens ?? this.allergens,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergens': allergens.map((e) => e.name).toList(),
      'dislikedIngredients': dislikedIngredients,
    };
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    final allergenNames =
        (json['allergens'] as List<dynamic>?)?.cast<String>() ?? [];
    final parsedAllergens = <AllergenType>{};
    for (final name in allergenNames) {
      for (final type in AllergenType.values) {
        if (type.name == name) {
          parsedAllergens.add(type);
        }
      }
    }

    return UserPreferences(
      allergens: parsedAllergens,
      dislikedIngredients:
          (json['dislikedIngredients'] as List<dynamic>?)?.cast<String>() ??
              const [],
    );
  }
}
