import React, { useState } from 'react';
import {
  ChevronLeft,
  Heart,
  Flame,
  Clock,
  Minus,
  Plus,
  CheckCircle,
  Circle,
  AlertTriangle,
  Lightbulb,
  ShieldAlert,
} from 'lucide-react';
import { Recipe, RecommendedRecipe } from '../types';
import { useApp } from '../context/AppContext';
import { IngredientNormalizer } from '../utils/ingredientNormalizer';
import { RecipeImage } from './RecipeImage';

interface RecipeDetailModalProps {
  recommendedRecipe: RecommendedRecipe;
  onClose: () => void;
}

export const RecipeDetailModal: React.FC<RecipeDetailModalProps> = ({
  recommendedRecipe,
  onClose,
}) => {
  const { pantryIngredients, ownedSeasonings, bookmarkedRecipeIds, toggleBookmark } = useApp();
  const recipe: Recipe = recommendedRecipe.recipe;
  const isBookmarked = bookmarkedRecipeIds.has(recipe.id);

  const [servings, setServings] = useState<number>(recipe.baseServings || 2);

  const isNow = recommendedRecipe.tier === 'canMakeNow';

  const ownedCanonicalNames = new Set([
    ...pantryIngredients.map((e) => IngredientNormalizer.normalizeName(e.name)),
    ...Array.from(ownedSeasonings).map((e) => IngredientNormalizer.normalizeName(e)),
  ]);

  const changeServings = (delta: number) => {
    setServings((prev) => Math.max(1, Math.min(10, prev + delta)));
  };

  // Scale nutrition info based on current servings
  const factor = servings;
  const scaledCalories = recipe.nutritionPerServing.caloriesKcal * factor;
  const scaledCarbs = Number((recipe.nutritionPerServing.carbsGrams * factor).toFixed(1));
  const scaledProtein = Number((recipe.nutritionPerServing.proteinGrams * factor).toFixed(1));
  const scaledFat = Number((recipe.nutritionPerServing.fatGrams * factor).toFixed(1));
  const scaledSodium = recipe.nutritionPerServing.sodiumMg * factor;

  const formatAmount = (baseAmount: number, unit: string) => {
    if (baseAmount <= 0) return unit;
    const scaled = (baseAmount * servings) / recipe.baseServings;
    if (Math.abs(scaled - Math.round(scaled)) < 0.05) {
      return `${Math.round(scaled)}${unit}`;
    }
    return `${scaled.toFixed(1)}${unit}`;
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-0 md:p-4 bg-black/60 backdrop-blur-sm animate-in fade-in duration-200">
      <div className="bg-white w-full h-full md:h-[90vh] md:max-w-xl md:rounded-3xl overflow-hidden shadow-2xl flex flex-col border border-[#E7E5E4]">
        {/* Scrollable Body */}
        <div className="flex-1 overflow-y-auto">
          {/* 1. Full-Bleed Food Photography Hero */}
          <div className="relative h-64 sm:h-72 w-full bg-[#F5F5F4] overflow-hidden">
            <RecipeImage
              src={recipe.imageUrl}
              alt={recipe.title}
              className="w-full h-full object-cover"
            />
            <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-black/20 to-transparent" />

            {/* Back button */}
            <button
              type="button"
              onClick={onClose}
              aria-label="뒤로가기"
              className="absolute top-4 left-4 p-2.5 bg-white/95 hover:bg-white rounded-full text-[#1C1917] shadow-md transition-transform active:scale-95 cursor-pointer"
              title="뒤로가기"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>

            {/* Bookmark heart button */}
            <button
              type="button"
              onClick={() => toggleBookmark(recipe.id)}
              data-key="bookmark_toggle_button"
              aria-label={isBookmarked ? '저장 취소' : '레시피 저장'}
              className="absolute top-4 right-4 p-2.5 bg-white/95 hover:bg-white rounded-full shadow-md transition-transform active:scale-95 cursor-pointer"
              title={isBookmarked ? '저장 취소' : '레시피 저장'}
            >
              <Heart
                className={`w-5 h-5 transition-colors ${
                  isBookmarked ? 'text-[#DC2626] fill-[#DC2626]' : 'text-[#1C1917]'
                }`}
              />
            </button>

            {/* Tier status over bottom of photo */}
            <div className="absolute bottom-4 left-5 right-5 flex items-center justify-between">
              <span
                className={`px-3 py-1 rounded-lg text-xs font-extrabold text-white ${
                  isNow ? 'bg-[#15803D]' : 'bg-[#1C1917]'
                }`}
              >
                {isNow ? '지금 바로 조리 가능' : '조금만 추가'}
              </span>
            </div>
          </div>

          <div className="p-5 sm:p-6 space-y-6">
            {/* 2. Title & Clean Unboxed Metadata */}
            <div>
              <p className="text-xs font-semibold text-[#78716C]">
                {recipe.category} · {recipe.sourceName}
              </p>

              <h1 className="text-xl sm:text-2xl font-extrabold text-[#1C1917] tracking-tight mt-1">
                {recipe.title}
              </h1>
              <p className="text-xs sm:text-sm text-[#57534E] mt-1 leading-relaxed">
                {recipe.subtitle}
              </p>

              {/* Inline Meta Stats (No Star / 100%) */}
              <div className="flex flex-wrap items-center gap-4 mt-3.5 text-xs sm:text-sm font-bold text-[#1C1917]">
                <div className="flex items-center gap-1.5">
                  <Flame className="w-4 h-4 text-[#15803D]" />
                  <span className="tabular-nums">
                    1인분 {recipe.nutritionPerServing.caloriesKcal} kcal
                  </span>
                </div>
                <div className="flex items-center gap-1.5">
                  <Clock className="w-4 h-4 text-[#78716C]" />
                  <span className="tabular-nums">
                    조리시간 {recipe.cookingTimeMinutes}분
                  </span>
                </div>
              </div>

              {/* Recommendation reason */}
              <div className="mt-3.5 p-3.5 bg-[#FAF9F6] border border-[#E7E5E4] rounded-xl text-xs text-[#1C1917] leading-relaxed">
                <span className="font-bold text-[#15803D]">추천 포인트: </span>
                {recommendedRecipe.recommendationReason}
              </div>
            </div>

            {/* 3. Nutrition Summary Card (Scaled to servings) */}
            <div className="p-4 bg-[#FAF9F6] border border-[#E7E5E4] rounded-2xl space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm font-extrabold text-[#1C1917]">
                  칼로리 및 영양 성분 계산
                </span>
                <span className="text-xs text-[#78716C] font-bold tabular-nums">
                  기준: {servings}인분 조리 시
                </span>
              </div>

              <div className="grid grid-cols-4 gap-2">
                <div className="bg-[#1C1917] text-white rounded-xl p-2.5 text-center">
                  <p className="text-[11px] font-medium text-[#A8A29E]">총 열량</p>
                  <p className="text-xs sm:text-sm font-extrabold tabular-nums mt-0.5">
                    {scaledCalories} kcal
                  </p>
                </div>
                <div className="bg-white border border-[#E7E5E4] rounded-xl p-2.5 text-center">
                  <p className="text-[11px] font-bold text-[#78716C]">탄수화물</p>
                  <p className="text-xs sm:text-sm font-extrabold text-[#1C1917] tabular-nums mt-0.5">
                    {scaledCarbs}g
                  </p>
                </div>
                <div className="bg-white border border-[#E7E5E4] rounded-xl p-2.5 text-center">
                  <p className="text-[11px] font-bold text-[#78716C]">단백질</p>
                  <p className="text-xs sm:text-sm font-extrabold text-[#1C1917] tabular-nums mt-0.5">
                    {scaledProtein}g
                  </p>
                </div>
                <div className="bg-white border border-[#E7E5E4] rounded-xl p-2.5 text-center">
                  <p className="text-[11px] font-bold text-[#78716C]">지방</p>
                  <p className="text-xs sm:text-sm font-extrabold text-[#1C1917] tabular-nums mt-0.5">
                    {scaledFat}g
                  </p>
                </div>
              </div>

              <p className="text-[11px] text-[#78716C] tabular-nums">
                • 예상 나트륨: {scaledSodium}mg (조리 시 사용하는 양념의 양에 따라 달라질 수 있습니다)
              </p>
            </div>

            {/* Uncertain quantity notice if applicable */}
            {recommendedRecipe.hasUncertainQuantities && (
              <div className="p-3.5 bg-[#FAF9F6] border border-[#E7E5E4] rounded-xl flex items-start gap-2.5 text-xs text-[#57534E]">
                <AlertTriangle className="w-4 h-4 text-[#B45309] shrink-0 mt-0.5" />
                <span>
                  보유 재료 중 정확한 수량이 입력되지 않은 항목이 있습니다. 조리 시작 전 아래의 인분별 필요 분량이 충분한지 확인해 주세요.
                </span>
              </div>
            )}

            {/* 4. Ingredients & Servings Stepper */}
            <div className="border border-[#E7E5E4] rounded-2xl p-4 sm:p-5 space-y-4">
              <div className="flex items-center justify-between">
                <h3 className="text-sm font-extrabold text-[#1C1917]">
                  필요한 식재료
                </h3>

                {/* Unified Charcoal Stepper (- 2인분 +) */}
                <div className="flex items-center bg-[#1C1917] rounded-xl text-white px-1.5 py-1">
                  <button
                    type="button"
                    onClick={() => changeServings(-1)}
                    disabled={servings <= 1}
                    data-key="decrease_servings_button"
                    aria-label="인분 감소"
                    className="p-1 hover:bg-white/20 rounded-lg disabled:opacity-30 disabled:hover:bg-transparent transition-colors cursor-pointer"
                    title="인분 감소"
                  >
                    <Minus className="w-3.5 h-3.5" />
                  </button>
                  <span className="px-2.5 text-xs font-extrabold tabular-nums">
                    {servings}인분
                  </span>
                  <button
                    type="button"
                    onClick={() => changeServings(1)}
                    disabled={servings >= 10}
                    data-key="increase_servings_button"
                    aria-label="인분 증가"
                    className="p-1 hover:bg-white/20 rounded-lg disabled:opacity-30 disabled:hover:bg-transparent transition-colors cursor-pointer"
                    title="인분 증가"
                  >
                    <Plus className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Ingredients Checklist */}
              <div className="divide-y divide-[#F5F5F4] pt-1">
                {recipe.ingredients.map((req, idx) => {
                  const canonical = IngredientNormalizer.normalizeName(req.name);
                  const isOwned = ownedCanonicalNames.has(canonical);
                  const substituteUsed = recommendedRecipe.availableSubstitutes[req.name];
                  const formattedAmt = formatAmount(req.baseAmount, req.unit);

                  return (
                    <div key={idx} className="py-2.5 space-y-1">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          {isOwned || substituteUsed ? (
                            <CheckCircle className="w-4 h-4 text-[#15803D]" />
                          ) : (
                            <Circle className="w-4 h-4 text-[#A8A29E]" />
                          )}
                          <span
                            className={`text-xs sm:text-sm ${
                              isOwned || substituteUsed
                                ? 'text-[#1C1917] font-semibold'
                                : 'text-[#78716C] font-medium'
                            }`}
                          >
                            {req.name}
                            {req.isOptional && ' (선택)'}
                            {req.isSeasoning && ' · 기본양념'}
                          </span>
                        </div>
                        <span className="text-xs sm:text-sm font-extrabold text-[#1C1917] tabular-nums">
                          {formattedAmt}
                        </span>
                      </div>

                      {req.substitutes && req.substitutes.length > 0 && (
                        <p className="text-[11px] text-[#78716C] pl-6">
                          {substituteUsed ? (
                            <span className="text-[#15803D] font-bold">
                              보유 중인 [{substituteUsed}](으)로 대체 가능합니다.
                            </span>
                          ) : (
                            `대체 가능 재료: ${req.substitutes.join(', ')}`
                          )}
                        </p>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* 5. Safety Warnings */}
            {recipe.safetyWarnings && recipe.safetyWarnings.length > 0 && (
              <div className="p-4 bg-[#FEF2F2] border border-[#FECACA] rounded-2xl space-y-2">
                <div className="flex items-center gap-2 text-[#DC2626]">
                  <ShieldAlert className="w-4 h-4" />
                  <h3 className="text-xs sm:text-sm font-extrabold">
                    식품 안전 및 조리 주의사항
                  </h3>
                </div>
                <ul className="text-xs text-[#1C1917] space-y-1 pl-4 list-disc leading-relaxed">
                  {recipe.safetyWarnings.map((warning, i) => (
                    <li key={i}>{warning}</li>
                  ))}
                </ul>
              </div>
            )}

            {/* 6. Step-by-Step Cooking Guide */}
            <div className="border border-[#E7E5E4] rounded-2xl p-4 sm:p-5 space-y-4">
              <h3 className="text-sm font-extrabold text-[#1C1917]">
                단계별 조리 방법
              </h3>
              <div className="space-y-4">
                {recipe.steps.map((step) => (
                  <div key={step.stepNumber} className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-lg bg-[#1C1917] text-white flex items-center justify-center text-xs font-extrabold tabular-nums shrink-0 mt-0.5">
                      {step.stepNumber}
                    </div>
                    <div className="flex-1 space-y-1.5">
                      <p className="text-xs sm:text-sm text-[#1C1917] leading-relaxed">
                        {step.instruction}
                      </p>
                      {step.tip && (
                        <div className="inline-flex items-center gap-1.5 p-2.5 bg-[#FAF9F6] border border-[#E7E5E4] rounded-xl text-[11px] font-medium text-[#57534E]">
                          <Lightbulb className="w-3.5 h-3.5 text-[#15803D] shrink-0" />
                          <span>조리 팁: {step.tip}</span>
                        </div>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* 7. Footer Reference */}
            <div className="p-3.5 bg-[#FAF9F6] border border-[#E7E5E4] rounded-xl text-[11px] text-[#78716C] space-y-1">
              <p className="font-bold text-[#1C1917]">
                레시피 출처 기준: {recipe.sourceName}
                {recipe.sourceUrl && ` (${recipe.sourceUrl})`}
              </p>
              <p>• 알레르기 유발 성분은 조리 전 실제 제품의 원재료명을 반드시 직접 확인하세요.</p>
            </div>
          </div>
        </div>

        {/* Bottom Close Button */}
        <div className="p-3.5 border-t border-[#E7E5E4] bg-white flex justify-end">
          <button
            type="button"
            onClick={onClose}
            className="w-full md:w-auto px-6 py-2.5 bg-[#1C1917] hover:bg-[#292524] text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
          >
            닫기
          </button>
        </div>
      </div>
    </div>
  );
};
