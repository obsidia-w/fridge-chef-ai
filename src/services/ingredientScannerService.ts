import { Ingredient, RecognitionConfidence, ScanAnalysisResult } from '../types';
import { IngredientNormalizer } from '../utils/ingredientNormalizer';

export class ScannerException extends Error {
  isRetryable: boolean;

  constructor(message: string, isRetryable = true) {
    super(message);
    this.name = 'ScannerException';
    this.isRetryable = isRetryable;
  }
}

export class AiResponseValidator {
  public static validateAndParse(
    rawJsonText: string,
    isDemoMode = false
  ): ScanAnalysisResult {
    const cleanedJson = this.extractJsonString(rawJsonText);
    if (!cleanedJson) {
      throw new ScannerException(
        'AI 응답에서 유효한 데이터를 찾지 못했습니다. 다시 시도하거나 직접 입력해 주세요.'
      );
    }

    let decoded: any;
    try {
      decoded = JSON.parse(cleanedJson);
    } catch (_) {
      throw new ScannerException(
        'AI 분석 결과 형식이 올바르지 않습니다. 다시 촬영하거나 수동 입력을 이용해 주세요.'
      );
    }

    if (!decoded || typeof decoded !== 'object') {
      throw new ScannerException('AI 응답 구조가 예상과 다릅니다.');
    }

    const rawList = decoded.ingredients;
    if (!Array.isArray(rawList)) {
      throw new ScannerException('식재료 목록을 추출할 수 없습니다.');
    }

    const scannedZones: string[] = Array.isArray(decoded.zonesScanned)
      ? decoded.zonesScanned.map((e: any) => String(e)).filter(Boolean)
      : [];

    const parsedItems: Ingredient[] = [];
    const excludedItems: string[] = [];

    for (let i = 0; i < rawList.length; i++) {
      const entry = rawList[i];
      if (!entry || typeof entry !== 'object') continue;

      const rawName = (entry.name || '').trim();
      const ocrLabel = (entry.ocrLabel || '').trim();
      const detectedZone = (entry.detectedZone || '').trim();
      const candidateName = rawName || ocrLabel;
      if (!candidateName) continue;

      const isFoodFlag = entry.isFood !== undefined ? Boolean(entry.isFood) : true;
      if (!isFoodFlag || IngredientNormalizer.isNonFoodItem(candidateName)) {
        excludedItems.push(candidateName);
        continue;
      }

      const confStr = String(entry.confidence || 'high').toLowerCase();
      let confidence: RecognitionConfidence = 'low';
      if (confStr.includes('high') || confStr.includes('높음') || confStr.includes('확실')) {
        confidence = 'high';
      } else if (confStr.includes('medium') || confStr.includes('보통') || confStr.includes('중간')) {
        confidence = 'medium';
      }

      const rawCategory = IngredientNormalizer.categoryFromString(entry.category || 'other');
      const uncertaintyReason = (entry.uncertaintyNote || '').trim();

      const requiresConfirmation = confidence !== 'high';
      let composedNote: string | null = null;
      if (requiresConfirmation) {
        const zonePrefix = detectedZone ? `[${detectedZone}] ` : '';
        composedNote = uncertaintyReason
          ? `${zonePrefix}${uncertaintyReason}`
          : `${zonePrefix}포장 또는 각도상 불분명하여 확인이 필요합니다.`;
      }

      // 중요 원칙: 이미지에서 알 수 없는 수량/중량/유통기한은 임의로 생성하지 않음!
      parsedItems.push({
        id: `scan_${Date.now()}_${i}`,
        name: candidateName,
        category: rawCategory,
        quantity: null,
        unit: null,
        confidence,
        uncertaintyNote: composedNote,
        isVerified: !requiresConfirmation,
      });
    }

    const normalizedList = IngredientNormalizer.normalizeAndDeduplicate(parsedItems);

    if (normalizedList.length === 0) {
      throw new ScannerException(
        '사진에서 식재료를 찾지 못했습니다. 냉장고 내부 조명이 보이도록 가까이에서 촬영하거나 직접 추가해 주세요.'
      );
    }

    const uncertainCount = normalizedList.filter(
      (e) => !e.isVerified && (e.confidence === 'medium' || e.confidence === 'low')
    ).length;

    const modeTag = isDemoMode ? '[샘플 시뮬레이션] ' : '[4구역 정밀 비전+OCR] ';
    const summary =
      uncertainCount > 0
        ? `${modeTag}총 ${normalizedList.length}개의 식재료를 인식했습니다. 불분명한 ${uncertainCount}개 항목을 확인해 주세요.`
        : `${modeTag}총 ${normalizedList.length}개의 식재료를 선명하게 인식했습니다.`;

    return {
      recognizedIngredients: normalizedList,
      excludedNonFoodItems: excludedItems,
      analysisSummary: summary,
      isDemoMode,
      scannedZones,
    };
  }

  private static extractJsonString(raw: string): string {
    const trimmed = raw.trim();
    const codeBlockMatch = trimmed.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (codeBlockMatch && codeBlockMatch[1]) {
      return codeBlockMatch[1].trim();
    }
    const firstBrace = trimmed.indexOf('{');
    const lastBrace = trimmed.lastIndexOf('}');
    if (firstBrace !== -1 && lastBrace !== -1 && lastBrace > firstBrace) {
      return trimmed.substring(firstBrace, lastBrace + 1);
    }
    return '';
  }
}

export class GeminiIngredientScannerService {
  public async analyzeImage({
    imageBytesBase64,
    mimeType = 'image/jpeg',
    demoPresetKey,
  }: {
    imageBytesBase64?: string;
    mimeType?: string;
    demoPresetKey?: string;
  }): Promise<ScanAnalysisResult> {
    if (demoPresetKey === 'simulate_error') {
      await new Promise((resolve) => setTimeout(resolve, 400));
      throw new ScannerException(
        '네트워크 불안정 또는 이미지 흐림으로 인해 식재료 분석에 실패했습니다. 다시 시도하거나 수동으로 입력해 주세요.'
      );
    }

    if (demoPresetKey) {
      await new Promise((resolve) => setTimeout(resolve, 450));
      const sampleJson = this.getDemoPresetJson(demoPresetKey);
      return AiResponseValidator.validateAndParse(sampleJson, true);
    }

    if (!imageBytesBase64) {
      throw new ScannerException('촬영된 이미지 데이터가 비어 있습니다. 다시 촬영해 주세요.');
    }

    return this.callServerSpatialOcrVisionApi(imageBytesBase64, mimeType);
  }

  private async callServerSpatialOcrVisionApi(
    base64Data: string,
    mimeType: string
  ): Promise<ScanAnalysisResult> {
    try {
      const res = await fetch('/api/scan', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          imageBytesBase64: base64Data,
          mimeType,
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new ScannerException(
          data?.error || `AI 서버 응답 오류 (코드: ${res.status}). 잠시 후 다시 시도해 주세요.`
        );
      }

      if (!data?.text) {
        throw new ScannerException('AI 분석 결과가 비어 있습니다.');
      }

      return AiResponseValidator.validateAndParse(data.text, false);
    } catch (e: any) {
      if (e instanceof ScannerException) throw e;
      throw new ScannerException(
        e?.message ||
          '네트워크 연결을 확인할 수 없거나 AI 요청 시간이 초과되었습니다. 다시 시도하거나 직접 입력해 주세요.'
      );
    }
  }

  private getDemoPresetJson(presetKey: string): string {
    switch (presetKey) {
      case 'meat_party':
        return JSON.stringify({
          zonesScanned: ['상단 선반', '중단 정육 코너', '하단 채소실'],
          ingredients: [
            { name: '돼지고기 목살', detectedZone: '중단 선반', category: 'meat', confidence: 'high', isFood: true },
            { name: '양파', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '손질대파', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '배추김치', detectedZone: '상단 선반', category: 'processed', confidence: 'high', isFood: true },
            { name: '플라스틱 반찬통', detectedZone: '상단 선반', category: 'other', confidence: 'high', isFood: false },
            { name: '두부', ocrLabel: '풀무원 국산콩 두부', detectedZone: '중단 선반', category: 'eggDairy', confidence: 'medium', isFood: true, uncertaintyNote: '불투명 용기 안에 들어 있어 두부인지 확인이 필요해요' },
          ],
        });
      case 'seafood_fresh':
        return JSON.stringify({
          zonesScanned: ['냉동/해산물 칸', '하단 채소실', '도어 포켓'],
          ingredients: [
            { name: '냉동새우', detectedZone: '해산물 칸', category: 'seafood', confidence: 'high', isFood: true },
            { name: '깐마늘', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '양파', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '지퍼백', detectedZone: '해산물 칸', category: 'other', confidence: 'high', isFood: false },
            { name: '버터', ocrLabel: '서울우유 버터', detectedZone: '도어 포켓', category: 'eggDairy', confidence: 'low', isFood: true, uncertaintyNote: '포장지 일부만 보여 치즈 또는 버터인지 확인해 주세요' },
          ],
        });
      case 'typical_fridge':
      default:
        return JSON.stringify({
          zonesScanned: ['상단 선반', '중단 선반', '하단 채소실', '도어 포켓'],
          ingredients: [
            { name: '달걀', detectedZone: '도어 포켓', category: 'eggDairy', confidence: 'high', isFood: true },
            { name: '유정란', detectedZone: '도어 포켓', category: 'eggDairy', confidence: 'high', isFood: true },
            { name: '익은김치', detectedZone: '상단 선반', category: 'processed', confidence: 'high', isFood: true },
            { name: '대파(손질)', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '양파', detectedZone: '하단 채소실', category: 'vegetable', confidence: 'high', isFood: true },
            { name: '햇반', ocrLabel: 'CJ 햇반', detectedZone: '상단 선반', category: 'grain', confidence: 'high', isFood: true },
            { name: '락앤락 용기', detectedZone: '상단 선반', category: 'other', confidence: 'high', isFood: false },
            { name: '스팸', ocrLabel: 'CJ 스팸 클래식', detectedZone: '중단 선반', category: 'processed', confidence: 'medium', isFood: true, uncertaintyNote: '캔 옆면만 보여 통조림 햄(스팸)이 맞는지 확인해 주세요' },
            { name: '찌개용 두부', ocrLabel: '풀무원 찌개두부', detectedZone: '중단 선반', category: 'eggDairy', confidence: 'low', isFood: true, uncertaintyNote: '서랍 안쪽에 가려져 있어 두부가 맞는지 확인이 필요해요' },
          ],
        });
    }
  }
}
