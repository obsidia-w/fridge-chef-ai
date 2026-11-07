import React, { useState } from 'react';
import { Settings, ChevronRight, UtensilsCrossed, Camera } from 'lucide-react';
import {
  CUISINE_DEFINITIONS,
  CuisineCategory,
  RecommendedRecipe,
} from '../types';
import { useApp } from '../context/AppContext';
import { RecipeImage } from '../components/RecipeImage';

interface RecommendationsViewProps {
  onOpenScanner: () => void;
  onOpenAllergySettings: () => void;
  onSelectRecipeDetail: (recipe: RecommendedRecipe) => void;
}

export const RecommendationsView: React.FC<RecommendationsViewProps> = ({
  onOpenScanner,
  onOpenAllergySettings,
  onSelectRecipeDetail,
}) => {
  const {
    pantryIngredients,
    preferences,
    selectedCategory,
    selectedMainIngredient,
    recommendations,
    selectCategory,
    selectMainIngredient,
  } = useApp();

  const [activeTier, setActiveTier] = useState<'canMakeNow' | 'almostReady'>('canMakeNow');

  const canMakeNowList = recommendations.filter((r) => r.tier === 'canMakeNow');
  const almostReadyList = recommendations.filter((r) => r.tier === 'almostReady');
  const currentList = activeTier === 'canMakeNow' ? canMakeNowList : almostReadyList;

  const hasUncertainQty = recommendations.some((r) => r.hasUncertainQuantities);

  return (
    <div className="min-h-screen bg-[#FAF9F6] pb-28">
      {/* Top Bar */}
      <header className="sticky top-0 z-20 bg-white/95 backdrop-blur-md border-b border-[#E7E5E4] px-4 sm:px-6 pt-3">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <h1 className="text-lg font-extrabold text-[#1C1917] tracking-tight">
            맞춤 요리 추천
          </h1>

          <button
            type="button"
            onClick={onOpenAllergySettings}
            data-key="open_allergy_settings_button"
            className="relative flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#FAF9F6] border border-[#E7E5E4] text-xs font-bold text-[#1C1917] hover:bg-[#F5F5F4] transition-colors cursor-pointer"
            title="알레르기 필터 설정"
          >
            <Settings className="w-4 h-4 text-[#78716C]" />
            <span>알레르기 필터</span>
            {preferences.allergens.length > 0 && (
              <span className="w-4 h-4 rounded-full bg-[#DC2626] text-white text-[10px] font-extrabold flex items-center justify-center tabular-nums">
                {preferences.allergens.length}
              </span>
            )}
          </button>
        </div>

        {/* 2 Tabs: 지금 바로 가능 / 조금만 추가 */}
        <div className="max-w-5xl mx-auto grid grid-cols-2 mt-3">
          <button
            type="button"
            onClick={() => setActiveTier('canMakeNow')}
            data-key="tab_can_make_now"
            className={`py-2.5 text-xs sm:text-sm font-extrabold border-b-2 transition-all cursor-pointer tabular-nums ${
              activeTier === 'canMakeNow'
                ? 'border-[#1C1917] text-[#1C1917]'
                : 'border-transparent text-[#78716C] hover:text-[#1C1917]'
            }`}
          >
            지금 바로 가능 ({canMakeNowList.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveTier('almostReady')}
            data-key="tab_almost_ready"
            className={`py-2.5 text-xs sm:text-sm font-extrabold border-b-2 transition-all cursor-pointer tabular-nums ${
              activeTier === 'almostReady'
                ? 'border-[#1C1917] text-[#1C1917]'
                : 'border-transparent text-[#78716C] hover:text-[#1C1917]'
            }`}
          >
            조금만 추가 ({almostReadyList.length})
          </button>
        </div>
      </header>

      {/* Filter Section */}
      <div className="bg-white border-b border-[#E7E5E4] px-4 sm:px-6 py-3">
        <div className="max-w-5xl mx-auto space-y-2.5">
          {/* Cuisine Filter Tabs */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5 no-scrollbar">
            {(Object.keys(CUISINE_DEFINITIONS) as CuisineCategory[]).map((catKey) => {
              const meta = CUISINE_DEFINITIONS[catKey];
              const isSelected = selectedCategory === catKey;
              return (
                <button
                  type="button"
                  key={catKey}
                  onClick={() => selectCategory(catKey)}
                  data-key={`cuisine_chip_${catKey}`}
                  className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                    isSelected
                      ? 'bg-[#1C1917] border-[#1C1917] text-white'
                      : 'bg-[#FAF9F6] border-[#E7E5E4] text-[#57534E] hover:border-[#1C1917]'
                  }`}
                >
                  {meta.label}
                </button>
              );
            })}
          </div>

          {/* Main Ingredient Selector Buttons */}
          {pantryIngredients.length > 0 && (
            <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5 no-scrollbar">
              <span className="text-xs font-bold text-[#78716C] pr-1 whitespace-nowrap shrink-0">
                주인공 재료:
              </span>

              <button
                type="button"
                onClick={() => selectMainIngredient(null)}
                data-key="main_ingredient_all_chip"
                className={`px-2.5 py-1 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                  selectedMainIngredient === null
                    ? 'bg-[#F5F5F4] border-[#1C1917] text-[#1C1917]'
                    : 'bg-white border-[#E7E5E4] text-[#78716C]'
                }`}
              >
                전체 재료
              </button>

              {pantryIngredients.map((ing) => {
                const isSelected = selectedMainIngredient === ing.name;
                return (
                  <button
                    type="button"
                    key={ing.id}
                    onClick={() => selectMainIngredient(ing.name)}
                    data-key={`main_ingredient_chip_${ing.name}`}
                    className={`px-2.5 py-1 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                      isSelected
                        ? 'bg-[#1C1917] border-[#1C1917] text-white'
                        : 'bg-white border-[#E7E5E4] text-[#57534E]'
                    }`}
                  >
                    {ing.name}
                  </button>
                );
              })}
            </div>
          )}

          {hasUncertainQty && (
            <p className="text-[11px] font-medium text-[#78716C] leading-tight">
              ※ 수량을 입력하지 않은 재료가 포함되어 있어 실제 보유 분량에 따라 조리 가능 여부가 달라질 수 있습니다.
            </p>
          )}
        </div>
      </div>

      {/* Recipe List */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-5">
        {currentList.length === 0 ? (
          <div className="p-8 text-center bg-white rounded-2xl border border-[#E7E5E4] space-y-4 my-6">
            <div className="w-12 h-12 rounded-2xl bg-[#F5F5F4] text-[#1C1917] flex items-center justify-center mx-auto">
              <UtensilsCrossed className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base font-extrabold text-[#1C1917]">
                {activeTier === 'canMakeNow'
                  ? '조건에 맞는 바로 가능 요리가 없습니다'
                  : '조금만 추가하면 가능한 요리가 없습니다'}
              </h3>
              <p className="text-xs text-[#78716C] mt-1.5 leading-relaxed">
                {activeTier === 'canMakeNow'
                  ? '다른 요리 카테고리나 메인 재료를 선택하거나 [조금만 추가] 탭을 확인해 보세요.'
                  : '식재료를 더 등록하거나 다른 요리 카테고리를 선택해 보세요.'}
              </p>
            </div>
            <button
              type="button"
              onClick={onOpenScanner}
              className="inline-flex items-center gap-1.5 px-4 py-2.5 bg-[#1C1917] hover:bg-[#292524] text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
            >
              <Camera className="w-4 h-4" />
              <span>냉장고 재료 스캔하기</span>
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {currentList.map((item) => {
              const isNow = item.tier === 'canMakeNow';
              const recipe = item.recipe;
              const nutrition = recipe.nutritionPerServing;

              return (
                <button
                  type="button"
                  key={recipe.id}
                  onClick={() => onSelectRecipeDetail(item)}
                  data-key={`recipe_card_${recipe.id}`}
                  className="group w-full text-left p-4 bg-white rounded-2xl border border-[#E7E5E4] hover:border-[#1C1917]/50 transition-all cursor-pointer flex flex-col justify-between gap-3"
                >
                  <div className="flex items-start gap-4">
                    {/* Food Photography Thumbnail */}
                    <div className="w-24 h-24 sm:w-28 sm:h-28 rounded-xl overflow-hidden bg-[#F5F5F4] shrink-0">
                      <RecipeImage
                        src={recipe.imageUrl}
                        alt={recipe.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                    </div>

                    <div className="flex-1 min-w-0 space-y-1.5">
                      <div className="flex items-center gap-2 text-xs">
                        <span
                          className={`font-bold ${
                            isNow ? 'text-[#15803D]' : 'text-[#B45309]'
                          }`}
                        >
                          {isNow
                            ? '바로 조리 가능'
                            : `재료 ${item.missingCoreIngredients.length}개 부족`}
                        </span>
                        <span className="text-[#D6D3D1]">·</span>
                        <span className="text-[#78716C] font-medium">
                          {recipe.category}
                        </span>
                        <span className="text-[#D6D3D1]">·</span>
                        <span className="text-[#78716C] font-medium tabular-nums">
                          {recipe.cookingTimeMinutes}분
                        </span>
                      </div>

                      <h3 className="text-base font-extrabold text-[#1C1917] line-clamp-1 tracking-tight">
                        {recipe.title}
                      </h3>

                      <p className="text-xs font-semibold text-[#57534E] tabular-nums">
                        {nutrition.caloriesKcal} kcal · 단백질 {nutrition.proteinGrams}g
                      </p>

                      <p className="text-xs text-[#78716C] line-clamp-2 leading-relaxed">
                        {item.recommendationReason}
                      </p>
                    </div>

                    <div className="w-7 h-7 rounded-lg bg-[#FAF9F6] group-hover:bg-[#1C1917] text-[#78716C] group-hover:text-white flex items-center justify-center shrink-0 mt-1 transition-colors">
                      <ChevronRight className="w-4 h-4" />
                    </div>
                  </div>

                  {/* Matched & Missing Ingredients Summary */}
                  <div className="pt-2.5 border-t border-[#F5F5F4] flex flex-wrap items-center gap-x-3 gap-y-1 text-xs">
                    {item.matchedIngredients.length > 0 && (
                      <span className="text-[#15803D] font-semibold">
                        보유: {item.matchedIngredients.join(', ')}
                      </span>
                    )}
                    {item.missingCoreIngredients.length > 0 && (
                      <span className="text-[#B45309] font-semibold">
                        추가 필요: {item.missingCoreIngredients.join(', ')}
                      </span>
                    )}
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};
