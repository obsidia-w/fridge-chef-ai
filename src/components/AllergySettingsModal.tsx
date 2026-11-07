import React from 'react';
import { X, AlertTriangle, ShieldCheck } from 'lucide-react';
import { ALLERGEN_DEFINITIONS, AllergenType, UserPreferences } from '../types';

interface AllergySettingsModalProps {
  preferences: UserPreferences;
  onUpdate: (newPrefs: UserPreferences) => void;
  onClose: () => void;
}

export const AllergySettingsModal: React.FC<AllergySettingsModalProps> = ({
  preferences,
  onUpdate,
  onClose,
}) => {
  const toggleAllergen = (type: AllergenType) => {
    const set = new Set(preferences.allergens);
    if (set.has(type)) {
      set.delete(type);
    } else {
      set.add(type);
    }
    onUpdate({
      ...preferences,
      allergens: Array.from(set),
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl border border-[#EAE4DC]">
        {/* Header */}
        <div className="flex items-center justify-between p-5 border-b border-[#E7E5E4]">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-[#15803D]" />
            <h2 className="text-base font-extrabold text-[#1C1917]">
              알레르기 및 제외 식재료 설정
            </h2>
          </div>
          <button
            type="button"
            onClick={onClose}
            aria-label="설정 창 닫기"
            className="p-1.5 text-stone-400 hover:text-stone-700 rounded-lg hover:bg-stone-100 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-5 space-y-4 max-h-[75vh] overflow-y-auto">
          <p className="text-xs text-[#78716C] leading-relaxed">
            선택하신 알레르기 항목이 포함된 레시피는 맞춤 추천 단계에서 엄격히 제외됩니다.
          </p>

          <div className="flex flex-wrap gap-2">
            {(Object.keys(ALLERGEN_DEFINITIONS) as AllergenType[]).map((type) => {
              const def = ALLERGEN_DEFINITIONS[type];
              const isSelected = preferences.allergens.includes(type);
              return (
                <button
                  type="button"
                  key={type}
                  onClick={() => toggleAllergen(type)}
                  data-key={`allergen_chip_${type}`}
                  className={`px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer border ${
                    isSelected
                      ? 'bg-[#FEF2F2] border-[#DC2626] text-[#DC2626]'
                      : 'bg-white border-[#E7E5E4] text-[#1C1917] hover:border-[#1C1917]'
                  }`}
                >
                  {def.label}
                  {isSelected && ' ✓'}
                </button>
              );
            })}
          </div>

          <div className="bg-[#F9F6F0] border border-[#EAE4DC] rounded-2xl p-3.5 space-y-1.5">
            <div className="flex items-center gap-1.5 text-[#B45309]">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span className="text-xs font-extrabold">안전 안내 및 면책 고지</span>
            </div>
            <p className="text-[11px] text-[#57534E] leading-relaxed">
              앱의 알레르기 필터는 등록된 대표 식재료를 기준으로 작동하며, 가공식품·소스류의 미량 교차 오염이나 완전한 알레르겐 안전성을 보장하지 않습니다. 조리 전 실제 제품의 성분표를 반드시 확인하세요.
            </p>
          </div>

          <button
            onClick={onClose}
            className="w-full py-3 bg-[#1C1917] hover:bg-black text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
          >
            설정 완료
          </button>
        </div>
      </div>
    </div>
  );
};
