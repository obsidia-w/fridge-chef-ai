import '../../features/pantry/domain/ingredient.dart';

/// 한국어 식재료 표준화, 포장지 OCR 브랜드명 정제, 동의어 매핑, 비식품 필터링 및 중복 병합 유틸리티
class IngredientNormalizer {
  IngredientNormalizer._();

  /// 포장지 OCR 인식 시 제거할 대표 식품 브랜드 접두어
  static const List<String> _brandPrefixes = [
    '풀무원',
    'CJ',
    '씨제이',
    '비비고',
    '오뚜기',
    '청정원',
    '대상',
    '종가집',
    '종가',
    '동원',
    '사조',
    '하림',
    '목우촌',
    '선진포크',
    '한돈',
    '서울우유',
    '매일유업',
    '매일',
    '남양',
    '연세우유',
    '빙그레',
    '대림선',
    '삼진어묵',
    '고래사',
    '백설',
    '해찬들',
    '샘표',
    '농심',
    '삼양',
    '팔도',
    '곰곰',
    '노브랜드',
    '피코크',
    '컬리',
  ];

  /// 동의어 -> 한국어 표준 식재료명 사전 (130+ 종 확장)
  static const Map<String, String> _synonymMap = {
    // 난류 / 유제품 / 두부
    '달걀': '계란',
    '계란(특란)': '계란',
    '특란': '계란',
    '왕란': '계란',
    '대란': '계란',
    '유정란': '계란',
    '구운계란': '계란',
    '메추리알': '계란',
    '찌개용 두부': '두부',
    '부침용 두부': '두부',
    ' 국산콩 두부': '두부',
    '모두부': '두부',
    '순두부': '두부',
    '연두부': '두부',
    '흰우유': '우유',
    '저지방우유': '우유',
    '멸균우유': '우유',
    '슬라이스치즈': '치즈',
    '체다치즈': '치즈',
    '모짜렐라치즈': '치즈',
    '피자치즈': '치즈',
    '슈레드치즈': '치즈',
    '파마산치즈': '치즈',
    '무염버터': '버터',
    '가염버터': '버터',
    '그릭요거트': '요거트',
    '플레인요거트': '요거트',
    '생크림': '우유',

    // 채소류
    '파': '대파',
    '쪽파': '대파',
    '실파': '대파',
    '손질대파': '대파',
    '대파(손질)': '대파',
    '다진파': '대파',
    '손질양파': '양파',
    '적양파': '양파',
    '자색양파': '양파',
    '깐마늘': '마늘',
    '통마늘': '마늘',
    '다진마늘': '마늘',
    '간마늘': '마늘',
    '편마늘': '마늘',
    '청양고추': '고추',
    '풋고추': '고추',
    '홍고추': '고추',
    '오이고추': '고추',
    '꽈리고추': '고추',
    '건고추': '고추',
    '느타리버섯': '버섯',
    '팽이버섯': '버섯',
    '새송이버섯': '버섯',
    '표고버섯': '버섯',
    '양송이버섯': '버섯',
    '목이버섯': '버섯',
    '애호박': '호박',
    '쥬키니호박': '호박',
    '단호박': '호박',
    '감자(알감자)': '감자',
    '수미감자': '감자',
    '알감자': '감자',
    '양배추(반통)': '양배추',
    '적양배추': '양배추',
    '채썬양배추': '양배추',
    '숙주': '숙주나물',
    '숙주나물': '숙주나물',
    '콩나물': '콩나물',
    '방울토마토': '토마토',
    '완숙토마토': '토마토',
    '파프리카': '파프리카',
    '피망': '파프리카',
    '청경채': '청경채',
    '브로콜리': '브로콜리',

    // 정육 / 고기류
    '돼지삼겹살': '삼겹살',
    '돼지고기 삼겹살': '삼겹살',
    '구이용 삼겹살': '삼겹살',
    '대패삼겹살': '삼겹살',
    '오겹살': '삼겹살',
    '돼지고기 목살': '돼지고기',
    '돼지목살': '돼지고기',
    '목살': '돼지고기',
    '돼지고기 앞다리살': '돼지고기',
    '앞다리살': '돼지고기',
    '뒷다리살': '돼지고기',
    '찌개용 돼지고기': '돼지고기',
    '돈육': '돼지고기',
    '다진돼지고기': '돼지고기',
    '돼지고기 다짐육': '돼지고기',
    '한우': '소고기',
    '쇠고기': '소고기',
    '우육': '소고기',
    '소불고기감': '소고기',
    '우삼겹': '소고기',
    '차돌박이': '소고기',
    '소고기 다짐육': '소고기',
    '국거리용 소고기': '소고기',
    '닭가슴살': '닭고기',
    '닭다리살': '닭고기',
    '닭안심': '닭고기',
    '닭볶음탕용 닭': '닭고기',
    '훈제오리': '오리고기',

    // 수산 / 해산물
    '자숙새우': '새우',
    '냉동새우': '새우',
    '칵테일새우': '새우',
    '생새우': '새우',
    '흰다리새우': '새우',
    '부산어묵': '어묵',
    '사각어묵': '어묵',
    '모둠어묵': '어묵',
    '오뎅': '어묵',
    '손질오징어': '오징어',
    '물오징어': '오징어',
    '진미채': '오징어',
    '자반고등어': '고등어',
    '순살고등어': '고등어',
    '국물멸치': '멸치',
    '잔멸치': '멸치',

    // 김치 / 반찬 / 가공식품
    '배추김치': '김치',
    '포기김치': '김치',
    '익은김치': '김치',
    '묵은지': '김치',
    '썰은김치': '김치',
    '맛김치': '김치',
    '통조림 햄': '스팸/통조림햄',
    '스팸': '스팸/통조림햄',
    '스팸 클래식': '스팸/통조림햄',
    '리챔': '스팸/통조림햄',
    '런천미트': '스팸/통조림햄',
    '비엔나소시지': '소시지',
    '프랑크소시지': '소시지',
    '줄줄이소시지': '소시지',
    '후랑크소시지': '소시지',
    '참치캔': '참치통조림',
    '동원참치': '참치통조림',
    '캔참치': '참치통조림',
    '살코기참치': '참치통조림',
    '조미김': '김',
    '구운김': '김',
    '김밥김': '김',
    '스파게티면': '파스타면',
    '링귀니': '파스타면',
    '펜네': '파스타면',
    '우동사리': '우동면',
    '냉동만두': '만두',
    '교자만두': '만두',

    // 곡류 / 밥 / 떡
    '즉석밥': '밥',
    '햇반': '밥',
    '오뚜기밥': '밥',
    '공기밥': '밥',
    '찬밥': '밥',
    '백미밥': '밥',
    '잡곡밥': '밥',
    '떡국떡': '떡',
    '떡볶이떡': '떡',
    '밀떡': '떡',
    '쌀떡': '떡',

    // 양념 / 소스류
    '진간장': '간장',
    '양조간장': '간장',
    '국간장': '간장',
    '맛간장': '간장',
    '설탕(백설탕)': '설탕',
    '백설탕': '설탕',
    '황설탕': '설탕',
    '꽃소금': '소금',
    '맛소금': '소금',
    '천일염': '소금',
    '구운소금': '소금',
    '카놀라유': '식용유',
    '콩기름': '식용유',
    '포도씨유': '식용유',
    '해바라기씨유': '식용유',
    '올리브유': '식용유',
    '올리브오일': '식용유',
    '들기름': '참기름',
    '토마토케첩': '케첩',
    '하인즈케첩': '케첩',
    '진한굴소스': '굴소스',
    '멸치액젓': '액젓',
    '까나리액젓': '액젓',
    '피시소스': '액젓',
  };

  /// 표준 식재료별 기본 카테고리 매핑
  static const Map<String, IngredientCategory> _defaultCategories = {
    '계란': IngredientCategory.eggDairy,
    '두부': IngredientCategory.eggDairy,
    '우유': IngredientCategory.eggDairy,
    '치즈': IngredientCategory.eggDairy,
    '버터': IngredientCategory.eggDairy,
    '요거트': IngredientCategory.eggDairy,
    '대파': IngredientCategory.vegetable,
    '양파': IngredientCategory.vegetable,
    '마늘': IngredientCategory.vegetable,
    '감자': IngredientCategory.vegetable,
    '고구마': IngredientCategory.vegetable,
    '당근': IngredientCategory.vegetable,
    '호박': IngredientCategory.vegetable,
    '양배추': IngredientCategory.vegetable,
    '고추': IngredientCategory.vegetable,
    '버섯': IngredientCategory.vegetable,
    '콩나물': IngredientCategory.vegetable,
    '숙주나물': IngredientCategory.vegetable,
    '시금치': IngredientCategory.vegetable,
    '오이': IngredientCategory.vegetable,
    '상추': IngredientCategory.vegetable,
    '깻잎': IngredientCategory.vegetable,
    '무': IngredientCategory.vegetable,
    '배추': IngredientCategory.vegetable,
    '토마토': IngredientCategory.vegetable,
    '파프리카': IngredientCategory.vegetable,
    '청경채': IngredientCategory.vegetable,
    '브로콜리': IngredientCategory.vegetable,
    '레몬': IngredientCategory.vegetable,
    '삼겹살': IngredientCategory.meat,
    '돼지고기': IngredientCategory.meat,
    '소고기': IngredientCategory.meat,
    '닭고기': IngredientCategory.meat,
    '오리고기': IngredientCategory.meat,
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
    '우동면': IngredientCategory.processed,
    '만두': IngredientCategory.processed,
    '김': IngredientCategory.processed,
    '밥': IngredientCategory.grain,
    '쌀': IngredientCategory.grain,
    '떡': IngredientCategory.grain,
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
    '액젓': IngredientCategory.seasoning,
  };

  /// 식품이 아닌 물체(비식품) 키워드 블랙리스트
  static const List<String> _nonFoodKeywords = [
    '용기',
    '반찬통',
    '밀폐용기',
    '플라스틱',
    '락앤락',
    '글라스락',
    '타파웨어',
    '비닐',
    '비닐봉지',
    '검은봉지',
    '지퍼백',
    '접시',
    '그릇',
    '냄비',
    '프라이팬',
    '선반',
    '냉장고',
    '문짝',
    '서랍',
    '트레이',
    '계란판',
    '라벨',
    '영수증',
    '병',
    '유리병',
    '페트병',
    '빈병',
    '수저',
    '포크',
    '랩',
    '호일',
    '아이스팩',
    '보냉팩',
    '행주',
    '손',
    '탈취제',
    '정수기',
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

  /// 식재료명을 한국어 표준 명칭으로 정규화 (포장지 OCR 브랜드명 제거 포함)
  static String normalizeName(String rawName) {
    var cleaned = rawName.trim();
    if (cleaned.isEmpty) return '';

    // 1. 직접 동의어 사전 매칭 확인
    if (_synonymMap.containsKey(cleaned)) {
      return _synonymMap[cleaned]!;
    }

    // 2. 괄호 안 부가 텍스트 및 용량 표기(예: 500g, 1L, 10구) 제거
    cleaned = cleaned
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(
          RegExp(r'\b\d+(\.\d+)?\s*(g|kg|ml|l|L|구|개입|봉|팩)\b'),
          '',
        )
        .trim();

    if (_synonymMap.containsKey(cleaned)) {
      return _synonymMap[cleaned]!;
    }

    // 3. 대표 식품 브랜드 접두어 제거 (예: "풀무원 국산콩 두부" -> "국산콩 두부" -> "두부")
    for (final brand in _brandPrefixes) {
      if (cleaned.startsWith('$brand ')) {
        cleaned = cleaned.substring(brand.length).trim();
      } else if (cleaned.startsWith(brand) && cleaned.length > brand.length) {
        cleaned = cleaned.substring(brand.length).trim();
      }
    }

    if (_synonymMap.containsKey(cleaned)) {
      return _synonymMap[cleaned]!;
    }

    // 4. 공백 제거 버전 비교
    final noSpace = cleaned.replaceAll(' ', '');
    for (final entry in _synonymMap.entries) {
      if (entry.key.replaceAll(' ', '') == noSpace) {
        return entry.value;
      }
    }

    // 5. 핵심 키워드 포함 매칭 (예: "신선한 무항생제 달걀" -> "계란", "국산 찌개용 두부" -> "두부")
    for (final entry in _synonymMap.entries) {
      if (entry.key.length >= 2 && cleaned.endsWith(entry.key)) {
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
        final bestConfidence =
            existing.confidence.index <= normalizedItem.confidence.index
                ? existing.confidence
                : normalizedItem.confidence;

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
