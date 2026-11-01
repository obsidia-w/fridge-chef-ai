/// 식재료 카테고리 구분
enum IngredientCategory {
  vegetable('채소/과일', '🥬'),
  meat('육류', '🥩'),
  seafood('수산물/해산물', '🐟'),
  eggDairy('계란/유제품/두부', '🥚'),
  processed('가공식품/햄/면류', '🥫'),
  grain('곡류/떡', '🍚'),
  seasoning('양념/소스', '🧂'),
  other('기타', '📦');

  final String label;
  final String emoji;
  const IngredientCategory(this.label, this.emoji);

  static IngredientCategory fromString(String value) {
    final normalized = value.trim().toLowerCase();
    for (final category in IngredientCategory.values) {
      if (category.name.toLowerCase() == normalized ||
          category.label.contains(normalized)) {
        return category;
      }
    }
    if (normalized.contains('채소') ||
        normalized.contains('야채') ||
        normalized.contains('과일') ||
        normalized.contains('버섯')) {
      return IngredientCategory.vegetable;
    }
    if (normalized.contains('육류') ||
        normalized.contains('고기') ||
        normalized.contains('돼지') ||
        normalized.contains('소고기') ||
        normalized.contains('닭')) {
      return IngredientCategory.meat;
    }
    if (normalized.contains('수산') ||
        normalized.contains('해산') ||
        normalized.contains('생선') ||
        normalized.contains('어패')) {
      return IngredientCategory.seafood;
    }
    if (normalized.contains('계란') ||
        normalized.contains('달걀') ||
        normalized.contains('유제품') ||
        normalized.contains('두부') ||
        normalized.contains('우유') ||
        normalized.contains('치즈')) {
      return IngredientCategory.eggDairy;
    }
    if (normalized.contains('가공') ||
        normalized.contains('햄') ||
        normalized.contains('면') ||
        normalized.contains('김치') ||
        normalized.contains('통조림')) {
      return IngredientCategory.processed;
    }
    if (normalized.contains('곡류') ||
        normalized.contains('밥') ||
        normalized.contains('쌀') ||
        normalized.contains('떡')) {
      return IngredientCategory.grain;
    }
    if (normalized.contains('양념') ||
        normalized.contains('조미료') ||
        normalized.contains('소스')) {
      return IngredientCategory.seasoning;
    }
    return IngredientCategory.other;
  }
}

/// AI 인식 확신도 (불분명한 재료는 사용자에게 확인을 요청하기 위함)
enum RecognitionConfidence {
  high('확실함', false),
  medium('보통', true),
  low('확인 필요', true);

  final String label;
  final bool requiresUserConfirmation;
  const RecognitionConfidence(this.label, this.requiresUserConfirmation);

  static RecognitionConfidence fromString(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'high':
      case '높음':
      case '확실':
        return RecognitionConfidence.high;
      case 'medium':
      case '보통':
      case '중간':
        return RecognitionConfidence.medium;
      case 'low':
      case '낮음':
      case '불확실':
      default:
        return RecognitionConfidence.low;
    }
  }
}

/// 식재료 엔티티
class Ingredient {
  final String id;
  final String name;
  final IngredientCategory category;
  final double? quantity;
  final String? unit;
  final RecognitionConfidence confidence;
  final String? uncertaintyNote;
  final bool isVerified;

  const Ingredient({
    required this.id,
    required this.name,
    required this.category,
    this.quantity,
    this.unit,
    this.confidence = RecognitionConfidence.high,
    this.uncertaintyNote,
    this.isVerified = true,
  });

  bool get needsConfirmation =>
      !isVerified && confidence.requiresUserConfirmation;

  bool get hasExplicitQuantity => quantity != null && quantity! > 0;

  String get quantityDisplay {
    if (quantity == null || quantity! <= 0) {
      return '수량 미지정';
    }
    final formatted = quantity! == quantity!.roundToDouble()
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(1);
    return '$formatted${unit ?? '개'}';
  }

  Ingredient copyWith({
    String? id,
    String? name,
    IngredientCategory? category,
    double? quantity,
    bool clearQuantity = false,
    String? unit,
    bool clearUnit = false,
    RecognitionConfidence? confidence,
    String? uncertaintyNote,
    bool? isVerified,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: clearUnit ? null : (unit ?? this.unit),
      confidence: confidence ?? this.confidence,
      uncertaintyNote: uncertaintyNote ?? this.uncertaintyNote,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'quantity': quantity,
      'unit': unit,
      'confidence': confidence.name,
      'uncertaintyNote': uncertaintyNote,
      'isVerified': isVerified,
    };
  }

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String? ?? json['name'] as String,
      name: json['name'] as String,
      category: IngredientCategory.fromString(
        json['category'] as String? ?? 'other',
      ),
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      confidence: RecognitionConfidence.fromString(
        json['confidence'] as String? ?? 'high',
      ),
      uncertaintyNote: json['uncertaintyNote'] as String?,
      isVerified: json['isVerified'] as bool? ?? true,
    );
  }
}
