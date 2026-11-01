import '../../features/pantry/domain/ingredient.dart';

/// 한국어 식재료 표준화, 동의어 매핑, 비식품 필터링 및 중복 병합 유틸리티
class IngredientNormalizer {
  IngredientNormalizer._();

  /// 동의어 -> 한국어 표준 식재료명 사전
  static const Map<String, String> _synonymMap = {
    '달걀': '계란',
    '계란(특란)': '계란',
    '유정란': '계란',
    '구운계란': '계란',
    '파': '대파',
    '쪽파': '대파',
    '손질대파': '대파',
    '대파(손질)': '대파',
    '돼지삼겹살': '삼겹살',
    '돼지고기 삼겹살': '삼겹살',
    '구이용 삼겹살': '삼겹살',
    '돼지고기 목살': '돼지고기',
    '돼지목살': '돼지고기',
    '돼지고기 앞다리살': '돼지고기',
    '돈육': '돼지고기',
    '다진돼지고기': '돼지고기',
    '한우': '소고기',
    '쇠고기': '소고기',
    '우육': '소고기',
    '소불고기감': '소고기',
    '닭가슴살': '닭고기',
    '닭다리살': '닭고기',
    '닭볶음탕용 닭': '닭고기',
    '배추김치': '김치',
    '포기김치': '김치',
    '익은김치': '김치',
    '묵은지': '김치',
    '찌개용 두부': '두부',
    '부침용 두부': '두부',
    '모두부': '두부',
    '깐마늘': '마늘',
    '통마늘': '마늘',
    '다진마늘': '마늘',
    '간마늘': '마늘',
    '청양고추': '고추',
    '풋고추': '고추',
    '홍고추': '고추',
    '느타리버섯': '버섯',
    '팽이버섯': '버섯',
    '새송이버섯': '버섯',
    '표고버섯': '버섯',
    '양송이버섯': '버섯',
    '통조림 햄': '스팸/통조림햄',
    '스팸': '스팸/통조림햄',
    '리챔': '스팸/통조림햄',
    '런천미트': '스팸/통조림햄',
    '비엔나소시지': '소시지',
    '프랑크소시지': '소시지',
    '줄줄이소시지': '소시지',
    '진간장': '간장',
    '양조간장': '간장',
    '국간장': '간장',
    '설탕(백설탕)': '설탕',
    '황설탕': '설탕',
    '꽃소금': '소금',
    '맛소금': '소금',
    '천일염': '소금',
    '카놀라유': '식용유',
    '콩기름': '식용유',
    '포도씨유': '식용유',
    '해바라기씨유': '식용유',
    '즉석밥': '밥',
    '햇반': '밥',
    '공기밥': '밥',
    '찬밥': '밥',
    '슬라이스치즈': '치즈',
    '체다치즈': '치즈',
    '모짜렐라치즈': '치즈',
    '애호박': '호박',
    '쥬키니호박': '호박',
    '감자(알감자)': '감자',
    '수미감자': '감자',
    '양배추(반통)': '양배추',
    '손질양파': '양파',
    '자숙새우': '새우',
    '냉동새우': '새우',
    '칵테일새우': '새우',
    '참치캔': '참치통조림',
    '동원참치': '참치통조림',
    '캔참치': '참치통조림',
  };

  /// 표준 식재료별 기본 카테고리 매핑
  static const Map<String, IngredientCategory> _defaultCategories = {
    '계란': IngredientCategory.eggDairy,
    '두부': IngredientCategory.eggDairy,
    '우유': IngredientCategory.eggDairy,
    '치즈': IngredientCategory.eggDairy,
    '버터': IngredientCategory.eggDairy,
    '대파': IngredientCategory.vegetable,
    '양파': IngredientCategory.vegetable,
    '마늘': IngredientCategory.vegetable,
    '감자': IngredientCategory.vegetable,
    '당근': IngredientCategory.vegetable,
    '호박': IngredientCategory.vegetable,
    '양배추': IngredientCategory.vegetable,
    '고추': IngredientCategory.vegetable,
    '버섯': IngredientCategory.vegetable,
    '콩나물': IngredientCategory.vegetable,
    '시금치': IngredientCategory.vegetable,
    '오이': IngredientCategory.vegetable,
    '상추': IngredientCategory.vegetable,
    '깻잎': IngredientCategory.vegetable,
    '무': IngredientCategory.vegetable,
    '배추': IngredientCategory.vegetable,
    '토마토': IngredientCategory.vegetable,
    '삼겹살': IngredientCategory.meat,
    '돼지고기': IngredientCategory.meat,
    '소고기': IngredientCategory.meat,
    '닭고기': IngredientCategory.meat,
    '베이컨': IngredientCategory.meat,
    '오징어': IngredientCategory.seafood,
    '새우': IngredientCategory.seafood,
    '고등어': IngredientCategory.seafood,
    '멸치': IngredientCategory.seafood,
    '어묵': IngredientCategory.seafood,
    '김치': IngredientCategory.processed,
    '스팸/통조림햄': IngredientCategory.processed,
    '소시지': IngredientCategory.processed,
    '참치통조림': IngredientCategory.processed,
    '라면': IngredientCategory.processed,
    '소면': IngredientCategory.processed,
    '파스타면': IngredientCategory.processed,
    '김': IngredientCategory.processed,
    '밥': IngredientCategory.grain,
    '쌀': IngredientCategory.grain,
    '떡볶이떡': IngredientCategory.grain,
    '식빵': IngredientCategory.grain,
    '간장': IngredientCategory.seasoning,
    '고추장': IngredientCategory.seasoning,
    '고춧가루': IngredientCategory.seasoning,
    '된장': IngredientCategory.seasoning,
    '소금': IngredientCategory.seasoning,
    '설탕': IngredientCategory.seasoning,
    '식용유': IngredientCategory.seasoning,
    '참기름': IngredientCategory.seasoning,
    '후추': IngredientCategory.seasoning,
    '굴소스': IngredientCategory.seasoning,
    '마요네즈': IngredientCategory.seasoning,
    '케첩': IngredientCategory.seasoning,
  };

  /// 식품이 아닌 물체(비식품) 키워드 블랙리스트
  static const List<String> _nonFoodKeywords = [
    '용기',
    '반찬통',
    '플라스틱',
    '락앤락',
    '타파웨어',
    '비닐',
    '비닐봉지',
    '지퍼백',
    '접시',
    '그릇',
    '냄비',
    '프라이팬',
    '선반',
    '냉장고',
    '문짝',
    '서랍',
    '라벨',
    '영수증',
    '병',
    '유리병',
    '페트병',
    '수저',
    '포크',
    '랩',
    '호일',
    '아이스팩',
    '보냉팩',
    '행주',
    '손',
  ];

  /// 기본 양념/조미료 목록
  static const List<String> defaultSeasonings = [
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
    '굴소스',
    '마요네즈',
    '케첩',
  ];

  /// 비식품 여부 판별
  static bool isNonFoodItem(String rawName) {
    final cleaned = rawName.trim();
    if (cleaned.isEmpty) return true;
    for (final keyword in _nonFoodKeywords) {
      if (cleaned == keyword ||
          cleaned.endsWith(' $keyword') ||
          cleaned.startsWith('$keyword ')) {
        return true;
      }
    }
    return false;
  }

  /// 식재료명을 한국어 표준 명칭으로 정규화
  static String normalizeName(String rawName) {
    var cleaned = rawName.trim();
    // 괄호 부가 설명 제거 전 직접 매핑 확인
    if (_synonymMap.containsKey(cleaned)) {
      return _synonymMap[cleaned]!;
    }

    // 괄호 안 부가 텍스트 제거 (예: "양파(중)" -> "양파")
    cleaned = cleaned.replaceAll(RegExp(r'\(.*?\)'), '').trim();
    if (_synonymMap.containsKey(cleaned)) {
      return _synonymMap[cleaned]!;
    }

    // 공백 제거 버전 비교
    final noSpace = cleaned.replaceAll(' ', '');
    for (final entry in _synonymMap.entries) {
      if (entry.key.replaceAll(' ', '') == noSpace) {
        return entry.value;
      }
    }

    return cleaned;
  }

  /// 정규화된 이름에 맞는 카테고리 추론
  static IngredientCategory inferCategory(
    String normalizedName, [
    IngredientCategory? fallback,
  ]) {
    if (_defaultCategories.containsKey(normalizedName)) {
      return _defaultCategories[normalizedName]!;
    }
    if (fallback != null && fallback != IngredientCategory.other) {
      return fallback;
    }
    return IngredientCategory.fromString(normalizedName);
  }

  /// 인식되거나 입력된 식재료 목록에서 비식품을 제외하고, 동의어를 표준화하며, 중복 항목을 병합
  static List<Ingredient> normalizeAndDeduplicate(List<Ingredient> rawItems) {
    final Map<String, Ingredient> merged = {};

    for (final item in rawItems) {
      if (isNonFoodItem(item.name)) {
        continue;
      }
      final canonicalName = normalizeName(item.name);
      if (canonicalName.isEmpty || isNonFoodItem(canonicalName)) {
        continue;
      }

      final inferredCategory = inferCategory(canonicalName, item.category);
      final normalizedItem = item.copyWith(
        name: canonicalName,
        category: inferredCategory,
      );

      if (!merged.containsKey(canonicalName)) {
        merged[canonicalName] = normalizedItem;
      } else {
        final existing = merged[canonicalName]!;
        // 확신도는 더 높은 쪽을 유지 (high < medium < low in enum index)
        final bestConfidence =
            existing.confidence.index <= normalizedItem.confidence.index
                ? existing.confidence
                : normalizedItem.confidence;

        // 수량이 둘 다 있고 단위가 같으면 합산, 하나만 있으면 있는 쪽 유지
        double? mergedQuantity = existing.quantity;
        String? mergedUnit = existing.unit ?? normalizedItem.unit;
        if (existing.quantity != null &&
            normalizedItem.quantity != null &&
            (existing.unit == normalizedItem.unit || existing.unit == null)) {
          mergedQuantity = existing.quantity! + normalizedItem.quantity!;
        } else {
          mergedQuantity = existing.quantity ?? normalizedItem.quantity;
        }

        merged[canonicalName] = existing.copyWith(
          confidence: bestConfidence,
          quantity: mergedQuantity,
          unit: mergedUnit,
          isVerified: existing.isVerified || normalizedItem.isVerified,
          uncertaintyNote:
              existing.uncertaintyNote ?? normalizedItem.uncertaintyNote,
        );
      }
    }

    // 확인이 필요한 항목(불확실한 항목)을 먼저 보여주거나 카테고리 순으로 정렬
    final result = merged.values.toList();
    result.sort((a, b) {
      if (a.needsConfirmation != b.needsConfirmation) {
        return a.needsConfirmation ? -1 : 1;
      }
      return a.name.compareTo(b.name);
    });
    return result;
  }
}
