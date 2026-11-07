import React, { useRef, useState } from 'react';
import {
  Camera,
  X,
  RefreshCw,
  Plus,
  AlertCircle,
  HelpCircle,
  Edit2,
  Trash2,
  Check,
} from 'lucide-react';
import { Ingredient, ScanAnalysisResult } from '../types';
import { useApp } from '../context/AppContext';
import { GeminiIngredientScannerService, ScannerException } from '../services/ingredientScannerService';
import { IngredientEditorModal } from './IngredientEditorModal';

interface ScannerModalProps {
  onClose: () => void;
  onFinishScan: () => void;
}

export const ScannerModal: React.FC<ScannerModalProps> = ({
  onClose,
  onFinishScan,
}) => {
  const { mergeVerifiedScanResults } = useApp();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [sourceDescription, setSourceDescription] = useState('');
  const [analysisSummary, setAnalysisSummary] = useState<string | null>(null);
  const [scannedZones, setScannedZones] = useState<string[]>([]);
  const [excludedItems, setExcludedItems] = useState<string[]>([]);
  const [draftIngredients, setDraftIngredients] = useState<Ingredient[]>([]);
  const [hasCompletedScan, setHasCompletedScan] = useState(false);
  const [editingItem, setEditingItem] = useState<Ingredient | null>(null);
  const [isAddingManual, setIsAddingManual] = useState(false);

  const scannerService = new GeminiIngredientScannerService();

  const runAnalysis = async ({
    base64Data,
    mimeType = 'image/jpeg',
    sourceLabel,
    demoPresetKey,
  }: {
    base64Data?: string;
    mimeType?: string;
    sourceLabel: string;
    demoPresetKey?: string;
  }) => {
    setIsAnalyzing(true);
    setErrorMessage(null);
    setSourceDescription(sourceLabel);

    try {
      const result: ScanAnalysisResult = await scannerService.analyzeImage({
        imageBytesBase64: base64Data,
        mimeType,
        demoPresetKey,
      });

      setHasCompletedScan(true);
      setAnalysisSummary(result.analysisSummary);
      setScannedZones(result.scannedZones);
      setExcludedItems(result.excludedNonFoodItems);
      setDraftIngredients(result.recognizedIngredients);
    } catch (e: any) {
      if (e instanceof ScannerException) {
        setErrorMessage(e.message);
      } else {
        setErrorMessage(
          '알 수 없는 오류로 인식에 실패했습니다. 다시 시도하거나 직접 입력해 주세요.'
        );
      }
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
      const resultStr = reader.result as string;
      const base64Content = resultStr.split(',')[1];
      runAnalysis({
        base64Data: base64Content,
        mimeType: file.type || 'image/jpeg',
        sourceLabel: `촬영 이미지 (${file.name})`,
      });
    };
    reader.readAsDataURL(file);
  };

  const handleConfirmSingle = (id: string) => {
    setDraftIngredients((prev) =>
      prev.map((item) =>
        item.id === id ? { ...item, isVerified: true, confidence: 'high' } : item
      )
    );
  };

  const handleRemoveDraftItem = (id: string) => {
    setDraftIngredients((prev) => prev.filter((item) => item.id !== id));
  };

  const handleConfirmAndSave = () => {
    if (draftIngredients.length === 0) {
      setErrorMessage('저장할 식재료가 없습니다. 최소 1개 이상 추가해 주세요.');
      return;
    }
    mergeVerifiedScanResults(draftIngredients);
    onFinishScan();
  };

  const uncertainCount = draftIngredients.filter(
    (e) => !e.isVerified && (e.confidence === 'medium' || e.confidence === 'low')
  ).length;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-0 md:p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full h-full md:h-[90vh] md:max-w-xl md:rounded-3xl overflow-hidden shadow-2xl flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-[#E7E5E4] bg-white sticky top-0 z-10">
          <div className="flex items-center gap-2">
            <Camera className="w-5 h-5 text-[#15803D]" />
            <h2 className="text-base font-extrabold text-[#1C1917]">
              AI 냉장고 식재료 스캔
            </h2>
          </div>

          <div className="flex items-center gap-2">
            <span className="flex items-center gap-1.5 px-3 py-1 rounded-xl text-xs font-bold bg-[#DCFCE7] text-[#15803D]">
              <span>4구역 비전 + OCR</span>
            </span>

            <button
              type="button"
              onClick={onClose}
              aria-label="스캔 창 닫기"
              className="p-1.5 text-stone-400 hover:text-stone-700 rounded-lg hover:bg-stone-100 transition-colors cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Hidden Camera / File Input */}
        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          capture="environment"
          onChange={handleFileChange}
          className="hidden"
        />

        {/* Content Area */}
        <div className="flex-1 overflow-y-auto p-4 md:p-6 space-y-4">
          {/* Guide Banner */}
          <div className="bg-[#1C1917] text-white p-4 rounded-2xl space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-extrabold px-2 py-0.5 rounded bg-[#15803D]">
                4구역 공간비전 + 한글 OCR 활성
              </span>
            </div>
            <p className="text-xs text-[#E7E5E4] leading-relaxed">
              • 인식률 2배 높이는 팁: 냉장고의 ①상단 ②중단 ③채소실 ④문짝 포켓이 잘 보이게 찍고, 두부·우유·어묵·소스류는 한글 라벨이 보이도록 촬영하면 OCR이 브랜드명을 자동 정제하여 정확히 인식합니다.
            </p>
          </div>

          {/* 1. Camera / Preset Trigger Section */}
          <div className="border border-[#E7E5E4] rounded-2xl p-4 bg-white space-y-3">
            <h3 className="text-sm font-extrabold text-[#1C1917]">
              1. 냉장고 식재료 카메라 촬영
            </h3>
            <p className="text-xs text-[#78716C]">
              냉장고 내부나 조리대 위 식재료를 카메라로 직접 촬영하거나 이미지를 업로드하면 4구역 분할 비전 + 한글 OCR이 식재료를 탐지합니다.
            </p>

            <button
              type="button"
              onClick={() => fileInputRef.current?.click()}
              data-key="scan_camera_button"
              className="w-full flex items-center justify-center gap-2 py-3 bg-[#1C1917] hover:bg-[#292524] text-white text-xs md:text-sm font-bold rounded-xl transition-all cursor-pointer"
            >
              <Camera className="w-4 h-4 text-[#4ADE80]" />
              <span>카메라로 냉장고 촬영 / 사진 선택 (고해상도 OCR)</span>
            </button>

            <div className="pt-2 border-t border-[#E7E5E4]">
              <p className="text-xs font-bold text-[#78716C] mb-2">
                빠른 시뮬레이션 / 테스트용 냉장고 촬영 샘플
              </p>
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() =>
                    runAnalysis({
                      sourceLabel: '자취방 기본 냉장고 샘플',
                      demoPresetKey: 'typical_fridge',
                    })
                  }
                  data-key="demo_preset_typical_button"
                  className="flex items-center gap-1.5 px-3 py-2 bg-white border border-[#E7E5E4] hover:border-[#1C1917] rounded-xl text-xs font-semibold text-[#1C1917] transition-colors cursor-pointer"
                >
                  <span>자취방 기본 냉장고 (중복/불확실 포함)</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    runAnalysis({
                      sourceLabel: '고기/찌개 재료 냉장고 샘플',
                      demoPresetKey: 'meat_party',
                    })
                  }
                  data-key="demo_preset_meat_button"
                  className="flex items-center gap-1.5 px-3 py-2 bg-white border border-[#E7E5E4] hover:border-[#1C1917] rounded-xl text-xs font-semibold text-[#1C1917] transition-colors cursor-pointer"
                >
                  <span>고기/찌개 재료 냉장고</span>
                </button>
                <button
                  type="button"
                  onClick={() =>
                    runAnalysis({
                      sourceLabel: '오류 시뮬레이션',
                      demoPresetKey: 'simulate_error',
                    })
                  }
                  data-key="demo_preset_error_button"
                  className="flex items-center gap-1.5 px-3 py-2 bg-white border border-[#FEE2E2] hover:border-[#DC2626] rounded-xl text-xs font-semibold text-[#DC2626] transition-colors cursor-pointer"
                >
                  <AlertCircle className="w-3.5 h-3.5 text-[#DC2626]" />
                  <span>인식 실패/오류 테스트</span>
                </button>
              </div>
            </div>
          </div>

          {/* Loading Indicator */}
          {isAnalyzing && (
            <div className="p-8 text-center bg-[#F9F6F0] rounded-2xl border border-[#EAE4DC] space-y-3">
              <RefreshCw className="w-7 h-7 text-[#C67C4E] animate-spin mx-auto" />
              <p className="text-sm font-extrabold text-[#18181B]">
                {sourceDescription} 분석 중...
              </p>
              <p className="text-xs text-[#57534E] leading-relaxed">
                1) 상단·중단·채소실·도어포켓 4구역 공간 스캔 중<br />
                2) 포장지 한글 라벨 OCR 판독 및 브랜드명 정제 중<br />
                3) 반찬통·비닐 등 비식품 자동 제외 중
              </p>
            </div>
          )}

          {/* Error / Fallback Box */}
          {errorMessage && (
            <div
              data-key="scan_error_fallback_card"
              className="p-4 bg-[#FEE2E2] border border-[#DC2626]/40 rounded-2xl space-y-3"
            >
              <div className="flex items-center gap-2 text-[#DC2626]">
                <AlertCircle className="w-5 h-5 shrink-0" />
                <h4 className="text-sm font-extrabold">
                  AI 식재료 인식에 실패했어요
                </h4>
              </div>
              <p className="text-xs text-[#18181B] leading-relaxed">
                {errorMessage}
              </p>
              <div className="flex flex-wrap gap-2 pt-1">
                <button
                  type="button"
                  onClick={() =>
                    runAnalysis({
                      sourceLabel: '자취방 기본 냉장고 재시도',
                      demoPresetKey: 'typical_fridge',
                    })
                  }
                  data-key="retry_scan_button"
                  className="flex items-center gap-1.5 px-3 py-2 bg-white border border-[#EAE4DC] hover:bg-stone-50 rounded-xl text-xs font-semibold text-[#18181B] transition-colors cursor-pointer"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  <span>샘플로 다시 시도</span>
                </button>
                <button
                  type="button"
                  onClick={() => setIsAddingManual(true)}
                  data-key="manual_fallback_button"
                  className="px-3 py-2 bg-white border border-[#EAE4DC] hover:bg-stone-50 rounded-xl text-xs font-semibold text-[#18181B] transition-colors cursor-pointer"
                >
                  직접 식재료 입력하기
                </button>
              </div>
            </div>
          )}

          {/* 2. Review & Refine Section */}
          {hasCompletedScan && !isAnalyzing && (
            <div className="space-y-3 pt-2">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-[#18181B]">
                  2. 인식 결과 확인 및 수정
                </h3>
                <button
                  type="button"
                  onClick={() => setIsAddingManual(true)}
                  className="flex items-center gap-1 text-xs font-bold text-[#9A5830] hover:underline cursor-pointer"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>직접 추가</span>
                </button>
              </div>

              {analysisSummary && (
                <p className="text-xs text-[#57534E] tabular-nums">
                  {analysisSummary}
                </p>
              )}

              {/* Scanned zones tags */}
              {scannedZones.length > 0 && (
                <div className="flex flex-wrap gap-1.5">
                  {scannedZones.map((zone, i) => (
                    <span
                      key={i}
                      className="px-2.5 py-1 bg-[#F9F2ED] rounded-lg text-[11px] font-bold text-[#9A5830]"
                    >
                      📍 스캔 구역: {zone}
                    </span>
                  ))}
                </div>
              )}

              {/* Excluded items banner */}
              {excludedItems.length > 0 && (
                <div className="p-2.5 bg-[#F9F6F0] border border-[#EAE4DC] rounded-xl text-[11px] text-[#57534E]">
                  🧹 자동 제외된 비식품 물체: {excludedItems.join(', ')}
                </div>
              )}

              {/* Uncertain warning banner */}
              {uncertainCount > 0 && (
                <div className="p-3 bg-[#FEF3C7] border border-[#F59E0B] rounded-xl flex items-center gap-2 text-xs text-[#B45309] tabular-nums">
                  <HelpCircle className="w-4 h-4 shrink-0" />
                  <span>
                    확인이 필요한 재료가 {uncertainCount}개 있어요. 맞으면 [맞아요]를 누르거나 이름을 수정해 주세요.
                  </span>
                </div>
              )}

              {/* Draft Items List */}
              <div className="space-y-2">
                {draftIngredients.map((item) => {
                  const needsCheck =
                    !item.isVerified &&
                    (item.confidence === 'medium' || item.confidence === 'low');

                  return (
                    <div
                      key={item.id}
                      className={`p-3 bg-white rounded-2xl border transition-colors ${
                        needsCheck ? 'border-[#F59E0B]' : 'border-[#EAE4DC]'
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2.5">
                          <span className="text-xl">
                            {item.category === 'eggDairy'
                              ? '🥚'
                              : item.category === 'meat'
                              ? '🥩'
                              : item.category === 'seafood'
                              ? '🐟'
                              : item.category === 'grain'
                              ? '🍚'
                              : item.category === 'processed'
                              ? '🥫'
                              : item.category === 'seasoning'
                              ? '🧂'
                              : '🥬'}
                          </span>
                          <div>
                            <div className="flex items-center gap-2">
                              <span className="text-sm font-extrabold text-[#18181B]">
                                {item.name}
                              </span>
                              <span
                                className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${
                                  needsCheck
                                    ? 'bg-[#FEF3C7] text-[#B45309]'
                                    : 'bg-[#DCFCE7] text-[#15803D]'
                                }`}
                              >
                                {needsCheck ? '⚠️ 확인 필요' : '✓ 인식 확실'}
                              </span>
                            </div>
                            <p className="text-[11px] text-[#57534E] tabular-nums mt-0.5">
                              {item.category} ·{' '}
                              {item.quantity
                                ? `${item.quantity}${item.unit || '개'}`
                                : '수량 미지정'}
                            </p>
                          </div>
                        </div>

                        <div className="flex items-center gap-1">
                          {needsCheck && (
                            <button
                              type="button"
                              onClick={() => handleConfirmSingle(item.id)}
                              data-key={`confirm_item_${item.name}`}
                              className="px-2.5 py-1 bg-[#15803D] hover:bg-[#166534] text-white rounded-lg text-xs font-bold transition-colors cursor-pointer"
                            >
                              맞아요
                            </button>
                          )}
                          <button
                            type="button"
                            onClick={() => setEditingItem(item)}
                            className="p-1.5 text-stone-400 hover:text-stone-700 rounded-lg hover:bg-stone-100 transition-colors cursor-pointer"
                            title="수정"
                            aria-label={`${item.name} 수정`}
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            type="button"
                            onClick={() => handleRemoveDraftItem(item.id)}
                            className="p-1.5 text-[#DC2626] hover:bg-[#FEE2E2] rounded-lg transition-colors cursor-pointer"
                            title="삭제"
                            aria-label={`${item.name} 삭제`}
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </div>

                      {needsCheck && item.uncertaintyNote && (
                        <p className="text-[11px] text-[#B45309] mt-2 pl-8">
                          💡 {item.uncertaintyNote}
                        </p>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        {hasCompletedScan && !isAnalyzing && (
          <div className="p-4 border-t border-[#EAE4DC] bg-white flex items-center gap-3">
            <button
              type="button"
              onClick={() => setIsAddingManual(true)}
              className="flex items-center gap-1.5 px-4 py-2.5 bg-white border border-[#EAE4DC] hover:bg-stone-50 text-xs font-bold text-[#18181B] rounded-xl transition-colors cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>누락 재료 추가</span>
            </button>

            <button
              type="button"
              onClick={handleConfirmAndSave}
              data-key="confirm_scan_results_button"
              className="flex-1 flex items-center justify-center gap-1.5 py-2.5 bg-[#15803D] hover:bg-[#166534] text-white text-xs md:text-sm font-extrabold rounded-xl transition-all cursor-pointer tabular-nums"
            >
              <Check className="w-4 h-4" />
              <span>재료 {draftIngredients.length}개 확정 및 요리 추천받기</span>
            </button>
          </div>
        )}

        {/* Inner Modals */}
        {editingItem && (
          <IngredientEditorModal
            initialIngredient={editingItem}
            onSave={(updated) => {
              setDraftIngredients((prev) =>
                prev.map((e) => (e.id === updated.id ? updated : e))
              );
              setEditingItem(null);
            }}
            onClose={() => setEditingItem(null)}
          />
        )}

        {isAddingManual && (
          <IngredientEditorModal
            onSave={(newItem) => {
              setDraftIngredients((prev) => [...prev, newItem]);
              setHasCompletedScan(true);
              setIsAddingManual(false);
            }}
            onClose={() => setIsAddingManual(false)}
          />
        )}
      </div>
    </div>
  );
};
