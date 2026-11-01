import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../../../core/utils/ingredient_normalizer.dart';
import '../../pantry/domain/ingredient.dart';

/// AI 이미지 인식 실패 예외
class ScannerException implements Exception {
  final String message;
  final bool isRetryable;

  const ScannerException(this.message, {this.isRetryable = true});

  @override
  String toString() => message;
}

/// AI 식재료 인식 결과 구조체
class ScanAnalysisResult {
  final List<Ingredient> recognizedIngredients;
  final List<String> excludedNonFoodItems;
  final String analysisSummary;
  final bool isDemoMode;

  const ScanAnalysisResult({
    required this.recognizedIngredients,
    this.excludedNonFoodItems = const [],
    required this.analysisSummary,
    this.isDemoMode = false,
  });
}

/// AI 응답 JSON을 엄격하게 검증하고 표준화된 식재료 엔티티로 변환하는 검증기
/// - 이미지에서 알 수 없는 수량, 중량, 유통기한, 신선도를 AI가 임의로 넣더라도 무시/제거합니다.
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

    final List<Ingredient> parsedItems = [];
    final List<String> excludedItems = [];

    for (var i = 0; i < rawList.length; i++) {
      final entry = rawList[i];
      if (entry is! Map<String, dynamic>) continue;

      final rawName = (entry['name'] as String?)?.trim() ?? '';
      if (rawName.isEmpty) continue;

      final isFoodFlag = entry['isFood'] as bool? ?? true;
      if (!isFoodFlag || IngredientNormalizer.isNonFoodItem(rawName)) {
        excludedItems.add(rawName);
        continue;
      }

      final confidence = RecognitionConfidence.fromString(
        entry['confidence'] as String?,
      );
      final rawCategory = IngredientCategory.fromString(
        entry['category'] as String? ?? 'other',
      );
      final uncertaintyReason = (entry['uncertaintyNote'] as String?)?.trim();

      // 중요 원칙: 이미지에서 알 수 없는 수량/중량/유통기한/신선도는 임의로 생성하지 않음!
      // 설령 AI가 임의의 수량이나 유통기한 필드를 반환하더라도 이를 폐기하고 null로 유지함.
      parsedItems.add(
        Ingredient(
          id: 'scan_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: rawName,
          category: rawCategory,
          quantity: null,
          unit: null,
          confidence: confidence,
          uncertaintyNote: confidence.requiresUserConfirmation
              ? (uncertaintyReason != null && uncertaintyReason.isNotEmpty
                  ? uncertaintyReason
                  : '포장 또는 각도상 불분명하여 확인이 필요합니다.')
              : null,
          isVerified: !confidence.requiresUserConfirmation,
        ),
      );
    }

    final normalizedList =
        IngredientNormalizer.normalizeAndDeduplicate(parsedItems);

    if (normalizedList.isEmpty) {
      throw const ScannerException(
        '사진에서 식재료를 찾지 못했습니다. 냉장고 내부가 잘 보이도록 다시 촬영하거나 직접 추가해 주세요.',
      );
    }

    final uncertainCount =
        normalizedList.where((e) => e.needsConfirmation).length;
    final summary = uncertainCount > 0
        ? '총 ${normalizedList.length}개의 식재료를 인식했습니다. 그중 불분명한 $uncertainCount개 항목을 확인해 주세요.'
        : '총 ${normalizedList.length}개의 식재료를 선명하게 인식했습니다.';

    return ScanAnalysisResult(
      recognizedIngredients: normalizedList,
      excludedNonFoodItems: excludedItems,
      analysisSummary: summary,
      isDemoMode: isDemoMode,
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
  Future<ScanAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? demoPresetKey,
  });
}

/// Gemini API (런타임 환경변수 주입) 및 스마트 데모 프리셋을 지원하는 구현체
/// - 모바일 앱 코드 내에 API 키를 절대 하드코딩하지 않습니다 (`String.fromEnvironment('GEMINI_API_KEY')`).
class GeminiIngredientScannerService implements IngredientScannerService {
  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  final http.Client? httpClient;

  GeminiIngredientScannerService({this.httpClient});

  bool get hasLiveApiKey => _apiKey.trim().isNotEmpty;

  @override
  Future<ScanAnalysisResult> analyzeImage({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? demoPresetKey,
  }) async {
    if (demoPresetKey == 'simulate_error') {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      throw const ScannerException(
        '네트워크 불안정 또는 이미지 흐림으로 인해 식재료 분석에 실패했습니다. 다시 시도하거나 수동으로 입력해 주세요.',
      );
    }

    // 런타임 API 키가 제공되었고 명시적 데모 프리셋이 아닌 경우 실제 Gemini 2.5 Flash 호출
    if (hasLiveApiKey && demoPresetKey == null && imageBytes.isNotEmpty) {
      return _callGeminiVisionApi(imageBytes: imageBytes, mimeType: mimeType);
    }

    // 오프라인/데모 검증 환경: 실제 사진 분석 파이프라인과 동일한 JSON Validator를 거침
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final sampleJson = _getDemoPresetJson(demoPresetKey ?? 'typical_fridge');
    return AiResponseValidator.validateAndParse(sampleJson, isDemoMode: true);
  }

  Future<ScanAnalysisResult> _callGeminiVisionApi({
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey',
    );

    const systemPrompt = '''
당신은 한국 가정집 냉장고 식재료 인식 전문 AI입니다.
다음 규칙을 엄격히 지켜 JSON 객체만 출력하세요:
1. 이미지에서 보이는 모든 식재료명을 한국어 표준 명칭으로 작성하세요.
2. 반찬통, 비닐봉지, 그릇, 냄비, 선반 등 식품이 아닌 물체는 isFood: false로 표시하거나 제외하세요.
3. 포장지에 가려져 있거나 불분명한 식재료는 추측을 확정 사실로 쓰지 말고 confidence를 "low" 또는 "medium"으로 설정한 뒤 uncertaintyNote에 이유를 적으세요.
4. 이미지에서 정확히 알 수 없는 수량, 중량, 유통기한, 신선도는 절대 임의로 생성하지 마세요.
출력 스키마:
{
  "ingredients": [
    {
      "name": "한국어 식재료명",
      "category": "vegetable|meat|seafood|eggDairy|processed|grain|seasoning|other",
      "confidence": "high|medium|low",
      "isFood": true,
      "uncertaintyNote": "불확실한 경우 확인 요청 사유"
    }
  ]
}
''';

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
                'temperature': 0.1,
              },
            }),
          )
          .timeout(const Duration(seconds: 20));

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
  "ingredients": [
    {"name": "돼지고기 목살", "category": "meat", "confidence": "high", "isFood": true},
    {"name": "양파", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "손질대파", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "배추김치", "category": "processed", "confidence": "high", "isFood": true},
    {"name": "플라스틱 반찬통", "category": "other", "confidence": "high", "isFood": false},
    {"name": "두부", "category": "eggDairy", "confidence": "medium", "isFood": true, "uncertaintyNote": "불투명 용기 안에 들어 있어 두부인지 확인이 필요해요"}
  ]
}
''';
      case 'seafood_fresh':
        return '''
{
  "ingredients": [
    {"name": "냉동새우", "category": "seafood", "confidence": "high", "isFood": true},
    {"name": "깐마늘", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "양파", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "지퍼백", "category": "other", "confidence": "high", "isFood": false},
    {"name": "버터", "category": "eggDairy", "confidence": "low", "isFood": true, "uncertaintyNote": "포장지 일부만 보여 치즈 또는 버터인지 확인해 주세요"}
  ]
}
''';
      case 'typical_fridge':
      default:
        return '''
{
  "ingredients": [
    {"name": "달걀", "category": "eggDairy", "confidence": "high", "isFood": true},
    {"name": "유정란", "category": "eggDairy", "confidence": "high", "isFood": true},
    {"name": "익은김치", "category": "processed", "confidence": "high", "isFood": true},
    {"name": "대파(손질)", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "양파", "category": "vegetable", "confidence": "high", "isFood": true},
    {"name": "햇반", "category": "grain", "confidence": "high", "isFood": true},
    {"name": "락앤락 용기", "category": "other", "confidence": "high", "isFood": false},
    {"name": "스팸", "category": "processed", "confidence": "medium", "isFood": true, "uncertaintyNote": "캔 옆면만 보여 통조림 햄(스팸)이 맞는지 확인해 주세요"},
    {"name": "찌개용 두부", "category": "eggDairy", "confidence": "low", "isFood": true, "uncertaintyNote": "서랍 안쪽에 가려져 있어 두부가 맞는지 확인이 필요해요"}
  ]
}
''';
    }
  }
}
