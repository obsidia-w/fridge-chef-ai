/// 알레르기 및 기피 식재료 카테고리
enum AllergenType {
  egg('난류(계란)', ['계란', '달걀', '메추리알', '마요네즈']),
  dairy('우유/유제품', ['우유', '치즈', '버터', '생크림', '요거트']),
  pork('돼지고기', ['돼지고기', '삼겹살', '베이컨', '스팸/통조림햄', '소시지']),
  beef('소고기', ['소고기', '쇠고기', '우육']),
  chicken('닭고기', ['닭고기', '닭가슴살']),
  shellfish('갑각류(새우/게)', ['새우', '게', '새우젓', '굴소스']),
  seafood('어패류/해산물', ['고등어', '오징어', '멸치', '어묵', '참치통조림', '조개', '굴']),
  soy('대두(콩/두부)', ['두부', '콩나물', '된장', '간장']),
  wheat('밀(면/빵류)', ['라면', '소면', '파스타면', '식빵', '부침가루', '밀가루']);

  final String label;
  final List<String> triggerIngredients;
  const AllergenType(this.label, this.triggerIngredients);
}

/// 요리 난이도
enum RecipeDifficulty {
  easy('쉬움', 1),
  medium('보통', 2),
  hard('어려움', 3);

  final String label;
  final int level;
  const RecipeDifficulty(this.label, this.level);
}

/// 개인화 설정 엔티티
class UserPreferences {
  final List<String> preferredCategories;
  final Set<AllergenType> allergens;
  final List<String> dislikedIngredients;
  final int maxCookingTimeMinutes;
  final RecipeDifficulty preferredDifficulty;
  final int defaultServings;

  const UserPreferences({
    this.preferredCategories = const ['한식', '자취요리', '일품요리'],
    this.allergens = const {},
    this.dislikedIngredients = const [],
    this.maxCookingTimeMinutes = 45,
    this.preferredDifficulty = RecipeDifficulty.medium,
    this.defaultServings = 2,
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
    List<String>? preferredCategories,
    Set<AllergenType>? allergens,
    List<String>? dislikedIngredients,
    int? maxCookingTimeMinutes,
    RecipeDifficulty? preferredDifficulty,
    int? defaultServings,
  }) {
    return UserPreferences(
      preferredCategories: preferredCategories ?? this.preferredCategories,
      allergens: allergens ?? this.allergens,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      maxCookingTimeMinutes:
          maxCookingTimeMinutes ?? this.maxCookingTimeMinutes,
      preferredDifficulty: preferredDifficulty ?? this.preferredDifficulty,
      defaultServings: defaultServings ?? this.defaultServings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'preferredCategories': preferredCategories,
      'allergens': allergens.map((e) => e.name).toList(),
      'dislikedIngredients': dislikedIngredients,
      'maxCookingTimeMinutes': maxCookingTimeMinutes,
      'preferredDifficulty': preferredDifficulty.name,
      'defaultServings': defaultServings,
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

    RecipeDifficulty difficulty = RecipeDifficulty.medium;
    for (final d in RecipeDifficulty.values) {
      if (d.name == json['preferredDifficulty']) {
        difficulty = d;
      }
    }

    return UserPreferences(
      preferredCategories:
          (json['preferredCategories'] as List<dynamic>?)?.cast<String>() ??
              const ['한식', '자취요리', '일품요리'],
      allergens: parsedAllergens,
      dislikedIngredients:
          (json['dislikedIngredients'] as List<dynamic>?)?.cast<String>() ??
              const [],
      maxCookingTimeMinutes: json['maxCookingTimeMinutes'] as int? ?? 45,
      preferredDifficulty: difficulty,
      defaultServings: json['defaultServings'] as int? ?? 2,
    );
  }
}
