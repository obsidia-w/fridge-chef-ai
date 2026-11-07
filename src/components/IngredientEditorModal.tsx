import React, { useState } from 'react';
import { Calendar, X } from 'lucide-react';
import {
  CATEGORY_INFO,
  Ingredient,
  IngredientCategory,
} from '../types';
import { IngredientNormalizer } from '../utils/ingredientNormalizer';

interface IngredientEditorModalProps {
  initialIngredient?: Ingredient | null;
  onSave: (ingredient: Ingredient) => void;
  onClose: () => void;
}

function getOffsetDateString(daysOffset: number): string {
  const d = new Date();
  d.setDate(d.getDate() + daysOffset);
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

export const IngredientEditorModal: React.FC<IngredientEditorModalProps> = ({
  initialIngredient,
  onSave,
  onClose,
}) => {
  const isEdit = Boolean(initialIngredient);

  const [name, setName] = useState(initialIngredient?.name || '');
  const [category, setCategory] = useState<IngredientCategory>(
    initialIngredient?.category || 'vegetable'
  );
  const [quantity, setQuantity] = useState<string>(
    initialIngredient?.quantity ? String(initialIngredient.quantity) : ''
  );
  const [unit, setUnit] = useState<string>(initialIngredient?.unit || '개');
  const [expirationDate, setExpirationDate] = useState<string>(
    initialIngredient?.expirationDate || ''
  );
  const [error, setError] = useState<string | null>(null);

  const handleNameChange = (val: string) => {
    setName(val);
    setError(null);
    const normalized = IngredientNormalizer.normalizeName(val);
    const inferred = IngredientNormalizer.inferCategory(normalized);
    if (inferred !== 'other') {
      setCategory(inferred);
    }
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const rawName = name.trim();
    if (!rawName) {
      setError('식재료 이름을 입력해 주세요.');
      return;
    }
    if (IngredientNormalizer.isNonFoodItem(rawName)) {
      setError(`식품이 아닌 물체(${rawName})는 등록할 수 없습니다.`);
      return;
    }

    const canonicalName = IngredientNormalizer.normalizeName(rawName);
    const parsedQty = quantity.trim() ? parseFloat(quantity.trim()) : null;
    const unitText = unit.trim();

    const result: Ingredient = {
      id: initialIngredient?.id || `manual_${Date.now()}`,
      name: canonicalName,
      category: IngredientNormalizer.inferCategory(canonicalName, category),
      quantity: parsedQty && parsedQty > 0 ? parsedQty : null,
      unit: parsedQty && parsedQty > 0 ? (unitText || '개') : null,
      expirationDate: expirationDate.trim() ? expirationDate.trim() : null,
      confidence: 'high',
      isVerified: true,
    };

    onSave(result);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white rounded-2xl w-full max-w-sm overflow-hidden shadow-2xl border border-[#EAE4DC]">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b border-[#EAE4DC]">
          <h2 className="text-base font-extrabold text-[#18181B]">
            {isEdit ? '식재료 수정' : '식재료 직접 추가'}
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="모달 닫기"
            className="p-1.5 text-stone-400 hover:text-stone-700 rounded-lg hover:bg-stone-100 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Form Body */}
        <form onSubmit={handleFormSubmit} className="p-4 space-y-4">
          <div>
            <label
              htmlFor="ingredient-name-input"
              className="block text-xs font-bold text-[#57534E] mb-1"
            >
              식재료명 (한국어)
            </label>
            <input
              id="ingredient-name-input"
              data-key="ingredient_name_input"
              type="text"
              autoFocus
              value={name}
              onChange={(e) => handleNameChange(e.target.value)}
              placeholder="예: 계란, 삼겹살, 대파, 두부"
              className="w-full px-3 py-2.5 text-sm bg-white border border-[#EAE4DC] focus:border-[#C67C4E] rounded-xl outline-none transition-colors"
            />
            {error && <p className="text-xs text-[#DC2626] mt-1">{error}</p>}
          </div>

          <div>
            <label
              htmlFor="ingredient-category-select"
              className="block text-xs font-bold text-[#57534E] mb-1"
            >
              카테고리
            </label>
            <select
              id="ingredient-category-select"
              data-key="ingredient_category_select"
              value={category}
              onChange={(e) => setCategory(e.target.value as IngredientCategory)}
              className="w-full px-3 py-2.5 text-sm bg-white border border-[#EAE4DC] focus:border-[#C67C4E] rounded-xl outline-none transition-colors cursor-pointer"
            >
              {(Object.keys(CATEGORY_INFO) as IngredientCategory[]).map((cat) => (
                <option key={cat} value={cat}>
                  {CATEGORY_INFO[cat].emoji} {CATEGORY_INFO[cat].label}
                </option>
              ))}
            </select>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1">
              <label
                htmlFor="ingredient-qty-input"
                className="text-xs font-bold text-[#57534E]"
              >
                수량 및 단위 (선택 사항)
              </label>
            </div>
            <div className="grid grid-cols-2 gap-2">
              <input
                id="ingredient-qty-input"
                data-key="ingredient_qty_input"
                aria-label="수량"
                type="number"
                step="any"
                min="0"
                value={quantity}
                onChange={(e) => setQuantity(e.target.value)}
                placeholder="미입력 가능 (예: 2)"
                className="w-full px-3 py-2.5 text-sm bg-white border border-[#EAE4DC] focus:border-[#C67C4E] rounded-xl outline-none transition-colors"
              />
              <input
                id="ingredient-unit-input"
                data-key="ingredient_unit_input"
                aria-label="단위"
                type="text"
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                placeholder="개, 모, g, 컵"
                className="w-full px-3 py-2.5 text-sm bg-white border border-[#EAE4DC] focus:border-[#C67C4E] rounded-xl outline-none transition-colors"
              />
            </div>
          </div>

          <div>
            <label
              htmlFor="ingredient-expiration-input"
              className="flex items-center gap-1.5 text-xs font-bold text-[#57534E] mb-1"
            >
              <Calendar className="w-3.5 h-3.5 text-[#15803D]" />
              <span>소비기한 (선택 사항 · 3일 이내 시 임박 알림)</span>
            </label>
            <input
              id="ingredient-expiration-input"
              data-key="ingredient_expiration_input"
              type="date"
              value={expirationDate}
              onChange={(e) => setExpirationDate(e.target.value)}
              className="w-full px-3 py-2 text-sm bg-white border border-[#E7E5E4] focus:border-[#1C1917] rounded-xl outline-none transition-colors tabular-nums"
            />
            <div className="flex flex-wrap items-center gap-1.5 mt-1.5">
              <button
                type="button"
                data-key="quick_expiry_today"
                onClick={() => setExpirationDate(getOffsetDateString(0))}
                className="px-2 py-1 rounded-lg text-[11px] font-bold bg-[#FEE2E2] text-[#DC2626] hover:bg-[#FECACA] transition-colors cursor-pointer"
              >
                오늘 만료
              </button>
              <button
                type="button"
                data-key="quick_expiry_2days"
                onClick={() => setExpirationDate(getOffsetDateString(2))}
                className="px-2 py-1 rounded-lg text-[11px] font-bold bg-[#FEF2F2] text-[#DC2626] border border-[#FECACA] hover:bg-[#FEE2E2] transition-colors cursor-pointer"
              >
                +2일 (임박)
              </button>
              <button
                type="button"
                data-key="quick_expiry_7days"
                onClick={() => setExpirationDate(getOffsetDateString(7))}
                className="px-2 py-1 rounded-lg text-[11px] font-semibold bg-[#FAF9F6] text-[#57534E] border border-[#E7E5E4] hover:bg-stone-100 transition-colors cursor-pointer"
              >
                +7일 (여유)
              </button>
              {expirationDate && (
                <button
                  type="button"
                  onClick={() => setExpirationDate('')}
                  className="px-2 py-1 rounded-lg text-[11px] font-semibold text-stone-400 hover:text-stone-600 cursor-pointer"
                >
                  초기화
                </button>
              )}
            </div>
          </div>

          <div className="flex items-center justify-end gap-2 pt-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-[#57534E] hover:bg-stone-100 rounded-xl transition-colors cursor-pointer"
            >
              취소
            </button>
            <button
              type="submit"
              data-key="save_ingredient_button"
              className="px-4 py-2 text-xs font-bold bg-[#1C1917] hover:bg-[#292524] text-white rounded-xl transition-colors cursor-pointer"
            >
              {isEdit ? '수정 완료' : '추가하기'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
