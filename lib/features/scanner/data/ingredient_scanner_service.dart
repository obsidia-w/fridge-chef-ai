import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../../core/utils/ingredient_normalizer.dart';
import '../../pantry/domain/ingredient.dart';

/// AI 이미지 인식 실패 예외
class ScannerException implements Exception {
  final String message;
  final bool isRetryable;
  final bool requiresApiKey;

  const ScannerException(
    this.message, {
    this.isRetryable = true,
    this.requiresApiKey = false,
  });

  @override
  String toString() => message;
}

/// AI 식재료 인식 결과 구조체
class ScanAnalysisResult {
  final List<Ingredient> recognizedIngredients;
  final List<String> excludedNonFoodItems;
  final String analysisSummary;
  final bool isDemoMode;
  final List<String> scannedZones;

  const ScanAnalysisResult({
    required this.recognizedIngredients,
    this.excludedNonFoodItems = const [],
    required this.analysisSummary,
    this.isDemoMode = false,
    this.scannedZones = const [],
  });
}

/// AI 응답 JSON을 엄격하게 검증하고 표준화된 식재료 엔티티로 변환하는 검증기
/// - 이미지에서 알 수 없는 수량, 중량, 유통기한, 신선도를 AI가 임의로 넣더라도 무시/제거합니다.
/// - 포장지 OCR 라벨(ocrLabel)과 탐지 구역(detectedZone) 정보를 결합하여 정확도를 높입니다.
/// - 비식품 항목을 분리하여 제외합니다.
/// - 불분명한 재료(medium/low confidence)는 확인 필요 상태(`isVerified: false`)로 설정합니다.
class AiResponseValidator {
  AiResponseValidator._();

  static ScanAnalysisResult validateAndParse(
    String rawJsonText, {
    bool isDemoMode = false,
  }) {
    final cleanedJson = _extractJsonString(rawJsonText);
    if (cleanedJson.isEmpty) {
      throw const ScannerException(
        'AI 응답에서 유효한 데이터를 찾지 못했습니다. 다시 시도하거나 직접 입력해 주세요.',
      );
    }

    final dynamic decoded;
    try {
      decoded = jsonDecode(cleanedJson);
    } catch (_) {
      throw const ScannerException(
        'AI 분석 결과 형식이 올바르지 않습니다. 다시 촬영하거나 수동 입력을 이용해 주세요.',
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ScannerException('AI 응답 구조가 예상과 다릅니다.');
    }

    final rawList = decoded['ingredients'];
    if (rawList is! List) {
      throw const ScannerException('식재료 목록을 추출할 수 없습니다.');
    }

    final rawZones = decoded['zonesScanned'];
    final List<String> scannedZones = rawZones is List
        ? rawZones.map((e) => e.toString()).where((s) => s.isNotEmpty).toList()
        : const [];

    final List<Ingredient> parsedItems = [];
    final List<String> excludedItems = [];

    for (var i = 0; i < rawList.length; i++) {
      final entry = rawList[i];
      if (entry is! Map<String, dynamic>) continue;

      final rawName = (entry['name'] as String?)?.trim() ?? '';
      final ocrLabel = (entry['ocrLabel'] as String?)?.trim() ?? '';
      final detectedZone = (entry['detectedZone'] as String?)?.trim() ?? '';
      final candidateName = rawName.isNotEmpty ? rawName : ocrLabel;
      if (candidateName.isEmpty) continue;

      final isFoodFlag = entry['isFood'] as bool? ?? true;
      if (!isFoodFlag || IngredientNormalizer.isNonFoodItem(candidateName)) {
        excludedItems.add(candidateName);
        continue;
      }

      final confidence = RecognitionConfidence.fromString(
        entry['confidence'] as String?,
      );
      final rawCategory = IngredientCategory.fromString(
        entry['category'] as String? ?? 'other',
      );
      final uncertaintyReason = (entry['uncertaintyNote'] as String?)?.trim();

      String? composedNote;
      if (confidence.requiresUserConfirmation) {
        final zonePrefix =
            detectedZone.isNotEmpty ? '[$detectedZone] ' : '';
        composedNote = (uncertaintyReason != null &&
                uncertaintyReason.isNotEmpty)
            ? '$zonePrefix$uncertaintyReason'
            : '$zonePrefix포장 또는 각도상 불분명하여 확인이 필요합니다.';
      }

      // 중요 원칙: 이미지에서 알 수 없는 수량/중량/유통기한/신선도는 임의로 생성하지 않음!
      parsedItems.add(
        Ingredient(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: candidateName,
          category: rawCategory,
          quantity: null,
          unit: null,
          confidence: confidence,
          uncertaintyNote: composedNote,
          isVerified: !confidence.requiresUserConfirmation,
        ),
      );
    }

    final normalizedList =
        IngredientNormalizer.normalizeAndDeduplicate(parsedItems);

    if (normalizedList.isEmpty) {
      throw const ScannerException(
        '사진에서 식재료를 찾지 못했습니다. 냉장고 내부 조명이 보이도록 가까이에서 촬영하거나 직접 추가해 주세요.',
      );
    }

    final uncertainCount =
        normalizedList.where((e) => e.needsConfirmation).length;
    final modeTag = isDemoMode ? '[샘플 시뮬레이션] ' : '[4구역 정밀 비전+OCR] ';
    final summary = uncertainCount > 0
        ? '$modeTag총 ${normalizedList.length}개의 식재료를 인식했습니다. 불분명한 $uncertainCount개 항목을 확인해 주세요.'
        : '$modeTag총 ${normalizedList.length}개의 식재료를 선명하게 인식했습니다.';

    return ScanAnalysisResult(
      recognizedIngredients: normalizedList,
      excludedNonFoodItems: excludedItems,
      analysisSummary: summary,
      isDemoMode: isDemoMode,
      scannedZones: scannedZones,
    );
  }

  static String _extractJsonString(String raw) {
    final trimmed = raw.trim();
    final codeBlockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```').firstMatch(trimmed);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)!.trim();
    }
    final firstBrace = trimmed.indexOf('{');
    final lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return trimmed.substring(firstBrace, lastBrace + 1);
    }
    return '';
  }
}

/// 식재료 이미지 인식 추상 인터페이스
abstract class IngredientScannerService {
  bool get hasLiveApiKey;

  Future<ScanAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? demoPresetKey,
  });
}

/// Gemini 2.5 Flash 4-Zone Spatial Grid + 한글 포장지 OCR 하이브리드 스캐너 구현체
/// - 빌드 타임 환경변수(`--dart-define=GEMINI_API_KEY`)와 앱 내 사용자 설정 API 키(`runtimeApiKey`)를 모두 지원합니다.
/// - 실제 카메라 촬영(`demoPresetKey == null`) 시 API 키가 없으면 가짜 더미 데이터를 몰래 반환하지 않고 명확히 안내합니다.
class GeminiIngredientScannerService implements IngredientScannerService {
  static const String _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  final String? runtimeApiKey;
  final http.Client? httpClient;

  GeminiIngredientScannerService({
    this.runtimeApiKey,
    this.httpClient,
  });

  String get _effectiveApiKey {
    final custom = runtimeApiKey?.trim() ?? '';
    if (custom.isNotEmpty) return custom;
    return _envApiKey.trim();
  }

  @override
  bool get hasLiveApiKey => _effectiveApiKey.isNotEmpty;

  @override
  Future<ScanAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? demoPresetKey,
  }) async {
    if (demoPresetKey == 'simulate_error') {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      throw const ScannerException(
        '네트워크 불안정 또는 이미지 흐림으로 인해 식재료 분석에 실패했습니다. 다시 시도하거나 수동으로 입력해 주세요.',
      );
    }

    // 1. 명시적 데모 프리셋 버튼을 누른 경우에만 샘플 시뮬레이션 반환
    if (demoPresetKey != null) {
      await Future<void>.delayed(const Duration(milliseconds: 700));
      final sampleJson = _getDemoPresetJson(demoPresetKey);
      return AiResponseValidator.validateAndParse(sampleJson, isDemoMode: true);
    }

    // 2. 실제 카메라 촬영 이미지를 분석하는 경우:
    // 과거 버그 수정: API 키가 없을 때 가짜 더미 재료를 반환하면 사용자가 인식률이 낮다고 오해하므로, 즉시 키 설정 안내!
    if (!hasLiveApiKey) {
      throw const ScannerException(
        '실제 냉장고 사진을 AI로 정밀 분석하려면 우측 상단 [🔑 AI 키 설정]에서 Gemini API 키를 입력해 주세요.\n(키가 설정되지 않은 상태에서는 가짜 더미 재료를 임의로 표시하지 않습니다.)',
        requiresApiKey: true,
      );
    }

    if (imageBytes.isEmpty) {
      throw const ScannerException('촬영된 이미지 데이터가 비어 있습니다. 다시 촬영해 주세요.');
    }

    return _callGeminiSpatialOcrVisionApi(
      imageBytes: imageBytes,
      mimeType: mimeType,
    );
  }

  /// 4구역 공간 분할(4-Zone Spatial Grid) + 한글 포장지 OCR + Structured Schema 호출
  Future<ScanAnalysisResult> _callGeminiSpatialOcrVisionApi({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_effectiveApiKey',
    );

    const systemPrompt = '''
당신은 한국 가정집 냉장고 및 주방 식재료 정밀 비전(Vision) + 한글 OCR 판독 전문 AI입니다.
사진 속 식재료 인식률을 극대화하기 위해 반드시 아래 [4단계 공간 분할 및 한글 OCR 스캔 절차]를 수행하세요:

[1단계: 4구역 공간 분할 스캔 (Spatial Grid Scanning)]
사진을 한 번에 뭉뚱그려 보지 말고 다음 구역별로 구석구석 스캔하여 작은 재료나 안쪽 재료도 빠짐없이 찾으세요:
- 구역 A (상단/중단 선반): 투명 반찬통 내부 내용물(김치, 멸치, 나물, 장류), 두부 팩, 계란 트레이, 즉석밥, 가공식품(스팸, 참치캔, 어묵, 소시지, 치즈, 버터)
- 구역 B (하단 채소실/서랍): 비닐이나 망에 들어 있는 채소류(대파, 양파, 마늘, 고추, 감자, 당근, 애호박, 양배추, 버섯류, 파프리카, 오이, 상추, 깻잎)
- 구역 C (정육/신선 코너): 포장 육류(삼겹살, 돼지고기 목살/다짐육, 소고기, 닭고기, 베이컨) 및 해산물(새우, 오징어, 고등어)
- 구역 D (냉장고 문짝 포켓): 우유, 요거트, 계란, 간장, 고추장, 된장, 케첩, 마요네즈, 굴소스, 참기름, 식용유 등 병/튜브/팩 제품

[2단계: 한글 포장지/라벨 OCR 판독]
- 포장지, 병 라벨, 두부/우유/어묵/햄/소스 용기에 적힌 한글 텍스트(예: "풀무원 두부", "서울우유", "진간장", "청양고추", "부산어묵", "스팸")를 읽고 ocrLabel 필드에 기록한 뒤, name에는 브랜드명을 뺀 한국어 표준 식재료명(예: "두부", "우유", "간장", "고추", "어묵", "스팸/통조림햄")을 적으세요.

[3단계: 비식품 분리 및 불확실성 정직 표기]
- 빈 반찬통, 비닐봉지 자체, 선반, 냄비, 그릇, 아이스팩 등 식품이 아닌 물체는 isFood: false로 분류하세요.
- 불투명 용기나 검은 비닐에 가려져 내용물이 100% 확실하지 않은 경우 추측을 확정 사실로 쓰지 말고 confidence를 "medium" 또는 "low"로 설정한 뒤 uncertaintyNote에 구체적 이유(예: "반투명 용기 안의 붉은 양념 반찬으로 김치인지 확인 필요")를 작성하세요.
- 이미지에서 알 수 없는 수량, 중량, 유통기한은 절대 임의로 생성하지 마세요.
''';

    final responseSchema = {
      'type': 'OBJECT',
      'properties': {
        'zonesScanned': {
          'type': 'ARRAY',
          'items': {'type': 'STRING'},
        },
        'ingredients': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'name': {'type': 'STRING'},
              'ocrLabel': {'type': 'STRING'},
              'detectedZone': {'type': 'STRING'},
              'category': {
                'type': 'STRING',
                'enum': [
                  'vegetable',
                  'meat',
                  'seafood',
                  'eggDairy',
                  'processed',
                  'grain',
                  'seasoning',
                  'other',
                ],
              },
              'confidence': {
                'type': 'STRING',
                'enum': ['high', 'medium', 'low'],
              },
              'isFood': {'type': 'BOOLEAN'},
              'uncertaintyNote': {'type': 'STRING'},
            },
            'required': ['name', 'category', 'confidence', 'isFood'],
          },
        },
      },
      'required': ['ingredients'],
    };

    try {
      final client = httpClient ?? http.Client();
      final response = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': systemPrompt},
                    {
                      'inline_data': {
                        'mime_type': mimeType,
                        'data': base64Encode(imageBytes),
                      },
                    },
                  ],
                },
              ],
              'generationConfig': {
                'responseMimeType': 'application/json',
                'responseSchema': responseSchema,
                'temperature': 0.15,
              },
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode == 400 || response.statusCode == 403) {
        throw const ScannerException(
          'Gemini API 키가 유효하지 않거나 권한이 없습니다. 우측 상단 [🔑 AI 키 설정]에서 키를 다시 확인해 주세요.',
          requiresApiKey: true,
        );
      }

      if (response.statusCode != 200) {
        throw ScannerException(
          'AI 서버 응답 오류 (코드: ${response.statusCode}). 잠시 후 다시 시도해 주세요.',
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List<dynamic>?;
      final text =
          candidates?.firstOrNull?['content']?['parts']?.firstOrNull?['text']
              as String?;

      if (text == null || text.isEmpty) {
        throw const ScannerException('AI 분석 결과가 비어 있습니다.');
      }

      return AiResponseValidator.validateAndParse(text, isDemoMode: false);
    } on ScannerException {
      rethrow;
    } catch (_) {
      throw const ScannerException(
        '네트워크 연결을 확인할 수 없거나 AI 요청 시간이 초과되었습니다. 다시 시도하거나 직접 입력해 주세요.',
      );
    }
  }

  String _getDemoPresetJson(String presetKey) {
    switch (presetKey) {
      case 'meat_party':
        return '''
{
  "zonesScanned": ["상단 선반", "중단 정육 코너", "하단 채소실"],
  "ingredients": [
    {"name": "돼지고기 목살", "detectedZone": "중단 선반", "category": "meat", "confidence": "high", "isFood": true},
    {"name": "양파", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "손질대파", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "배추김치", "detectedZone": "상단 선반", "category": "processed", "confidence": "high", "isFood": true},
    {"name": "플라스틱 반찬통", "detectedZone": "상단 선반", "category": "other", "confidence": "high", "isFood": false},
    {"name": "두부", "ocrLabel": "풀무원 국산콩 두부", "detectedZone": "중단 선반", "category": "eggDairy", "confidence": "medium", "isFood": true, "uncertaintyNote": "불투명 용기 안에 들어 있어 두부인지 확인이 필요해요"}
  ]
}
''';
      case 'seafood_fresh':
        return '''
{
  "zonesScanned": ["냉동/해산물 칸", "하단 채소실", "도어 포켓"],
  "ingredients": [
    {"name": "냉동새우", "detectedZone": "해산물 칸", "category": "seafood", "confidence": "high", "isFood": true},
    {"name": "깐마늘", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "양파", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "지퍼백", "detectedZone": "해산물 칸", "category": "other", "confidence": "high", "isFood": false},
    {"name": "버터", "ocrLabel": "서울우유 버터", "detectedZone": "도어 포켓", "category": "eggDairy", "confidence": "low", "isFood": true, "uncertaintyNote": "포장지 일부만 보여 치즈 또는 버터인지 확인해 주세요"}
  ]
}
''';
      case 'typical_fridge':
      default:
        return '''
{
  "zonesScanned": ["상단 선반", "중단 선반", "하단 채소실", "도어 포켓"],
  "ingredients": [
    {"name": "달걀", "detectedZone": "도어 포켓", "category": "eggDairy", "confidence": "high", "isFood": true},
    {"name": "유정란", "detectedZone": "도어 포켓", "category": "eggDairy", "confidence": "high", "isFood": true},
    {"name": "익은김치", "detectedZone": "상단 선반", "category": "processed", "confidence": "high", "isFood": true},
    {"name": "대파(손질)", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "양파", "detectedZone": "하단 채소실", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "햇반", "ocrLabel": "CJ 햇반", "detectedZone": "상단 선반", "category": "grain", "confidence": "high", "isFood": true},
    {"name": "락앤락 용기", "detectedZone": "상단 선반", "category": "other", "confidence": "high", "isFood": false},
    {"name": "스팸", "ocrLabel": "CJ 스팸 클래식", "detectedZone": "중단 선반", "category": "processed", "confidence": "medium", "isFood": true, "uncertaintyNote": "캔 옆면만 보여 통조림 햄(스팸)이 맞는지 확인해 주세요"},
    {"name": "찌개용 두부", "ocrLabel": "풀무원 찌개두부", "detectedZone": "중단 선반", "category": "eggDairy", "confidence": "low", "isFood": true, "uncertaintyNote": "서랍 안쪽에 가려져 있어 두부가 맞는지 확인이 필요해요"}
  ]
}
''';
    }
  }
}
