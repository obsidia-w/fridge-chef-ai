import React, { useState } from 'react';
import {
  Plus,
  Edit2,
  Trash2,
  Refrigerator,
  Camera,
  AlertTriangle,
  ArrowUpRight,
} from 'lucide-react';
import {
  CATEGORY_INFO,
  CUISINE_DEFINITIONS,
  CuisineCategory,
  getExpirationStatus,
  Ingredient,
  IngredientCategory,
  RecommendedRecipe,
} from '../types';
import { useApp } from '../context/AppContext';
import { Header } from '../components/Header';
import { RecipeImage } from '../components/RecipeImage';
import { IngredientNormalizer } from '../utils/ingredientNormalizer';

interface PantryViewProps {
  onStartScan: () => void;
  onGoToRecommendations: () => void;
  onOpenManualAdd: () => void;
  onOpenEditIngredient: (item: Ingredient) => void;
  onSelectRecipeDetail: (recipe: RecommendedRecipe) => void;
}

export const PantryView: React.FC<PantryViewProps> = ({
  onStartScan,
  onGoToRecommendations,
  onOpenManualAdd,
  onOpenEditIngredient,
  onSelectRecipeDetail,
}) => {
  const {
    pantryIngredients,
    ownedSeasonings,
    selectedCategory,
    selectedMainIngredient,
    recommendations,
    selectCategory,
    selectMainIngredient,
    removeIngredient,
    toggleSeasoning,
    clearPantry,
  } = useApp();

  const [selectedFilterCategory, setSelectedFilterCategory] = useState<IngredientCategory | null>(null);
  const [onlyExpiringFilter, setOnlyExpiringFilter] = useState<boolean>(false);
  const [deletingItem, setDeletingItem] = useState<Ingredient | null>(null);

  const canMakeNowCount = recommendations.filter((r) => r.tier === 'canMakeNow').length;

  const expiringIngredients = pantryIngredients.filter(
    (item) => getExpirationStatus(item.expirationDate).isWarning
  );

  const filteredIngredients = pantryIngredients
    .filter((item) => {
      if (selectedFilterCategory && item.category !== selectedFilterCategory) {
        return false;
      }
      if (onlyExpiringFilter && !getExpirationStatus(item.expirationDate).isWarning) {
        return false;
      }
      return true;
    })
    .sort((a, b) => {
      const statusA = getExpirationStatus(a.expirationDate);
      const statusB = getExpirationStatus(b.expirationDate);
      if (statusA.isWarning !== statusB.isWarning) {
        return statusA.isWarning ? -1 : 1;
      }
      if (statusA.daysRemaining != null && statusB.daysRemaining != null) {
        return statusA.daysRemaining - statusB.daysRemaining;
      }
      return 0;
    });

  const previewRecipes = recommendations.slice(0, 4);

  const usedCategories = new Set(pantryIngredients.map((e) => e.category));

  const handleSelectAsMainAndGo = (ingredientName: string) => {
    selectMainIngredient(ingredientName);
    onGoToRecommendations();
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] pb-28">
      {/* 1. Unified Header */}
      <Header
        ingredientCount={pantryIngredients.length}
        canMakeNowCount={canMakeNowCount}
        onOpenManualAdd={onOpenManualAdd}
        onStartScan={onStartScan}
        onGoToRecommendations={onGoToRecommendations}
      />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 pt-6 space-y-8">
        {/* 2. World Cuisine Category Tabs & Food Photography Recipe Grid */}
        <section className="space-y-4">
          <div className="flex items-center justify-between">
            <div>
              <h2 className="text-lg font-extrabold text-[#1C1917] tracking-tight">
                맞춤 추천 요리
              </h2>
              <p className="text-xs text-[#78716C] mt-0.5">
                냉장고 속 식재료와 기본 양념으로 만들 수 있는 검증된 레시피
              </p>
            </div>
            <button
              type="button"
              onClick={onGoToRecommendations}
              className="text-xs font-bold text-[#1C1917] hover:text-[#15803D] transition-colors cursor-pointer whitespace-nowrap"
            >
              전체 레시피 보기 →
            </button>
          </div>

          {/* Interactive Cuisine Filter Tabs */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar">
            {(Object.keys(CUISINE_DEFINITIONS) as CuisineCategory[]).map((catKey) => {
              const meta = CUISINE_DEFINITIONS[catKey];
              const isSelected = selectedCategory === catKey;
              return (
                <button
                  type="button"
                  key={catKey}
                  onClick={() => selectCategory(catKey)}
                  data-key={`home_cuisine_pill_${catKey}`}
                  className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-bold whitespace-nowrap transition-all cursor-pointer border shrink-0 ${
                    isSelected
                      ? 'bg-[#1C1917] border-[#1C1917] text-white'
                      : 'bg-white border-[#E7E5E4] text-[#57534E] hover:border-[#1C1917] hover:text-[#1C1917]'
                  }`}
                >
                  <span>{meta.label}</span>
                </button>
              );
            })}
          </div>

          {/* Main Ingredient Filter Bar */}
          {pantryIngredients.length > 0 && (
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar">
              <span className="text-xs font-bold text-[#78716C] pr-1 whitespace-nowrap shrink-0">
                주인공 재료:
              </span>

              <button
                type="button"
                onClick={() => selectMainIngredient(null)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                  selectedMainIngredient === null
                    ? 'bg-[#F5F5F4] border-[#1C1917] text-[#1C1917]'
                    : 'bg-white border-[#E7E5E4] text-[#78716C] hover:text-[#1C1917]'
                }`}
              >
                전체 재료
              </button>

              {pantryIngredients.map((ing) => {
                const isSelected = selectedMainIngredient === ing.name;
                const expStatus = getExpirationStatus(ing.expirationDate);
                return (
                  <button
                    type="button"
                    key={ing.id}
                    onClick={() => selectMainIngredient(ing.name)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                      isSelected
                        ? 'bg-[#1C1917] border-[#1C1917] text-white'
                        : expStatus.isWarning
                        ? 'bg-[#FEF2F2] border-[#FECACA] text-[#DC2626]'
                        : 'bg-white border-[#E7E5E4] text-[#57534E] hover:border-[#1C1917]'
                    }`}
                  >
                    <span>{ing.name}</span>
                    {expStatus.isWarning && (
                      <span
                        className="w-1.5 h-1.5 rounded-full bg-[#DC2626] shrink-0"
                        title={expStatus.label || '소비기한 임박'}
                      />
                    )}
                  </button>
                );
              })}
            </div>
          )}

          {/* 3. Recipe Preview Grid (Real Food Photography, No Star / 100%) */}
          {previewRecipes.length === 0 ? (
            <div className="p-5 bg-white rounded-2xl border border-[#E7E5E4] flex items-center justify-between text-xs text-[#78716C]">
              <span>선택한 카테고리/메인 재료에 맞는 요리가 없습니다.</span>
              <button
                type="button"
                onClick={() => {
                  selectCategory('all');
                  selectMainIngredient(null);
                }}
                className="font-bold text-[#1C1917] hover:underline cursor-pointer ml-2 shrink-0"
              >
                필터 초기화
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
              {previewRecipes.map((item) => {
                const isNow = item.tier === 'canMakeNow';
                return (
                  <button
                    type="button"
                    key={item.recipe.id}
                    onClick={() => onSelectRecipeDetail(item)}
                    className="group bg-white rounded-2xl border border-[#E7E5E4] hover:border-[#1C1917]/40 overflow-hidden transition-all cursor-pointer flex flex-col justify-between text-left"
                  >
                    {/* Top 4:3 Food Photograph */}
                    <div className="relative aspect-[4/3] w-full overflow-hidden bg-[#F5F5F4]">
                      <RecipeImage
                        src={item.recipe.imageUrl}
                        alt={item.recipe.title}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      />
                      <div className="absolute inset-0 bg-gradient-to-t from-black/45 via-transparent to-transparent" />

                      {/* Single clean status indicator */}
                      <div className="absolute bottom-2.5 left-2.5">
                        <span
                          className={`text-[11px] font-bold px-2.5 py-1 rounded-lg backdrop-blur-xs ${
                            isNow
                              ? 'bg-[#15803D]/95 text-white'
                              : 'bg-[#1C1917]/90 text-white'
                          }`}
                        >
                          {isNow ? '바로 조리 가능' : `+재료 ${item.missingCoreIngredients.length}개`}
                        </span>
                      </div>
                    </div>

                    {/* Card Body */}
                    <div className="p-3.5 flex-1 flex flex-col justify-between space-y-2.5 w-full">
                      <div className="space-y-1">
                        <p className="text-[11px] font-medium text-[#78716C] tabular-nums truncate">
                          {item.recipe.category} · {item.recipe.cookingTimeMinutes}분
                        </p>
                        <h3 className="text-sm font-extrabold text-[#1C1917] line-clamp-1 tracking-tight">
                          {item.recipe.title}
                        </h3>
                      </div>

                      {/* Bottom Calories & Action Affordance */}
                      <div className="flex items-center justify-between pt-2 border-t border-[#F5F5F4] w-full">
                        <p className="text-xs font-bold text-[#57534E] tabular-nums">
                          {item.recipe.nutritionPerServing.caloriesKcal} kcal · 단백질 {item.recipe.nutritionPerServing.proteinGrams}g
                        </p>

                        <div className="w-7 h-7 rounded-lg bg-[#F5F5F4] group-hover:bg-[#1C1917] text-[#1C1917] group-hover:text-white flex items-center justify-center transition-colors shrink-0">
                          <ArrowUpRight className="w-4 h-4" />
                        </div>
                      </div>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </section>

        {/* 4. Pantry Ingredients Management Section */}
        <section className="space-y-3.5 pt-2">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <h2 className="text-lg font-extrabold text-[#1C1917] tabular-nums whitespace-nowrap">
                내 냉장고 보유 재료 ({pantryIngredients.length})
              </h2>
              {expiringIngredients.length > 0 && (
                <span
                  data-key="expiring_summary_badge"
                  className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-lg text-[11px] font-extrabold bg-[#FEF2F2] text-[#DC2626] border border-[#FECACA] tabular-nums whitespace-nowrap shrink-0"
                >
                  <AlertTriangle className="w-3 h-3 text-[#DC2626] shrink-0" />
                  <span>임박 {expiringIngredients.length}</span>
                </span>
              )}
            </div>
            <div className="flex items-center gap-3 shrink-0">
              {pantryIngredients.length > 0 && (
                <button
                  type="button"
                  onClick={clearPantry}
                  className="text-xs font-semibold text-[#78716C] hover:text-[#DC2626] transition-colors cursor-pointer whitespace-nowrap"
                  title="전체 비우기"
                >
                  전체 비우기
                </button>
              )}
              <button
                type="button"
                onClick={onOpenManualAdd}
                className="flex items-center gap-1 text-xs font-bold text-[#1C1917] hover:text-[#15803D] transition-colors cursor-pointer whitespace-nowrap"
              >
                <Plus className="w-4 h-4 shrink-0" />
                <span>수동 추가</span>
              </button>
            </div>
          </div>

          {/* Subtle Red Warning Callout when expiring items exist */}
          {expiringIngredients.length > 0 && (
            <div
              data-key="expiring_alert_banner"
              className="p-3.5 bg-[#FEF2F2] border border-[#FECACA] rounded-2xl flex items-center justify-between gap-3"
            >
              <div className="flex items-center gap-2.5 text-xs text-[#991B1B]">
                <AlertTriangle className="w-4 h-4 text-[#DC2626] shrink-0" />
                <span>
                  소비기한이 임박한 재료(
                  <strong className="font-extrabold text-[#DC2626]">
                    {expiringIngredients.map((e) => e.name).join(', ')}
                  </strong>
                  )가 있습니다. 우선 소진할 수 있는 요리를 추천받아 보세요.
                </span>
              </div>
              <button
                type="button"
                data-key="filter_expiring_toggle"
                onClick={() => setOnlyExpiringFilter((prev) => !prev)}
                className={`px-3 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                  onlyExpiringFilter
                    ? 'bg-[#DC2626] border-[#DC2626] text-white'
                    : 'bg-white border-[#FECACA] text-[#DC2626] hover:bg-[#FEE2E2]/60'
                }`}
              >
                {onlyExpiringFilter ? '전체 재료 보기' : '임박 재료만'}
              </button>
            </div>
          )}

          {/* Category Filter Tabs */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 no-scrollbar">
            <button
              type="button"
              onClick={() => {
                setSelectedFilterCategory(null);
                setOnlyExpiringFilter(false);
              }}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                selectedFilterCategory === null && !onlyExpiringFilter
                  ? 'bg-[#1C1917] border-[#1C1917] text-white'
                  : 'bg-white border-[#E7E5E4] text-[#57534E] hover:text-[#1C1917]'
              }`}
            >
              전체
            </button>

            {(Object.keys(CATEGORY_INFO) as IngredientCategory[])
              .filter((c) => usedCategories.has(c))
              .map((catKey) => {
                const info = CATEGORY_INFO[catKey];
                const isSelected = selectedFilterCategory === catKey;
                return (
                  <button
                    type="button"
                    key={catKey}
                    onClick={() =>
                      setSelectedFilterCategory(isSelected ? null : catKey)
                    }
                    className={`flex items-center gap-1 px-3 py-1.5 rounded-lg text-xs font-bold whitespace-nowrap transition-colors cursor-pointer border shrink-0 ${
                      isSelected
                        ? 'bg-[#1C1917] border-[#1C1917] text-white'
                        : 'bg-white border-[#E7E5E4] text-[#57534E] hover:text-[#1C1917]'
                    }`}
                  >
                    <span>{info.label}</span>
                  </button>
                );
              })}
          </div>

          {/* Ingredient Items (1 col on mobile, 2 cols on desktop) */}
          {filteredIngredients.length === 0 ? (
            <div className="p-8 bg-white rounded-2xl border border-[#E7E5E4] text-center space-y-3">
              <div className="w-12 h-12 rounded-2xl bg-[#F5F5F4] text-[#1C1917] flex items-center justify-center mx-auto">
                <Refrigerator className="w-6 h-6" />
              </div>
              <div>
                <h4 className="text-sm font-extrabold text-[#1C1917]">
                  등록된 식재료가 없습니다
                </h4>
                <p className="text-xs text-[#78716C] mt-1">
                  카메라로 냉장고를 촬영하면 AI가 식재료를 한 번에 정리해 드립니다.
                </p>
              </div>
              <button
                type="button"
                onClick={onStartScan}
                className="inline-flex items-center gap-1.5 px-4 py-2.5 bg-[#1C1917] hover:bg-[#292524] text-white text-xs font-bold rounded-xl transition-colors cursor-pointer"
              >
                <Camera className="w-4 h-4" />
                <span>카메라로 재료 인식하기</span>
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-2.5">
              {filteredIngredients.map((item) => {
                const isMainSelected = selectedMainIngredient === item.name;
                const catInfo = CATEGORY_INFO[item.category] || CATEGORY_INFO.other;
                const expStatus = getExpirationStatus(item.expirationDate);
                const isExpiringWarning = expStatus.isWarning;

                return (
                  <div
                    key={item.id}
                    data-key={`pantry_item_card_${item.name}`}
                    className={`p-3.5 rounded-2xl border transition-all flex items-center justify-between ${
                      isMainSelected
                        ? 'bg-white border-[#1C1917]'
                        : isExpiringWarning
                        ? 'bg-[#FEF2F2]/50 border-[#FCA5A5] hover:border-[#EF4444]'
                        : 'bg-white border-[#E7E5E4] hover:border-[#A8A29E]'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div
                        className={`relative w-11 h-11 rounded-xl flex items-center justify-center text-xl shrink-0 border ${
                          isMainSelected
                            ? 'bg-[#1C1917] text-white border-[#1C1917]'
                            : isExpiringWarning
                            ? 'bg-[#FEF2F2] border-[#FECACA]'
                            : 'bg-[#FAF9F6] border-[#E7E5E4]'
                        }`}
                      >
                        {catInfo.emoji}
                        {isExpiringWarning && (
                          <span
                            data-key={`expiration_dot_${item.name}`}
                            className="absolute -top-1 -right-1 w-3 h-3 rounded-full bg-[#DC2626] ring-2 ring-white"
                            title={expStatus.label || '소비기한 임박'}
                          />
                        )}
                      </div>

                      <div className="min-w-0">
                        <div className="flex flex-wrap items-center gap-1.5">
                          <span className="text-sm font-extrabold text-[#1C1917]">
                            {item.name}
                          </span>
                          {isExpiringWarning && expStatus.label && (
                            <span
                              data-key={`expiration_warning_${item.name}`}
                              className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md text-[11px] font-bold bg-[#FEE2E2] text-[#DC2626] tabular-nums"
                            >
                              <AlertTriangle className="w-3 h-3 text-[#DC2626] shrink-0" />
                              <span>{expStatus.label}</span>
                            </span>
                          )}
                          {isMainSelected && (
                            <span className="text-[11px] font-bold text-[#15803D]">
                              · 주인공 선택됨
                            </span>
                          )}
                        </div>
                        <p className="text-xs text-[#78716C] tabular-nums mt-0.5 truncate">
                          {catInfo.label} ·{' '}
                          {item.quantity
                            ? `${item.quantity}${item.unit || '개'}`
                            : '수량 미지정'}
                          {expStatus.urgency === 'fresh' && expStatus.label && (
                            <span> · {expStatus.label}</span>
                          )}
                        </p>
                      </div>
                    </div>

                    <div className="flex items-center gap-1 shrink-0 ml-2">
                      <button
                        type="button"
                        onClick={() => handleSelectAsMainAndGo(item.name)}
                        data-key={`select_main_from_pantry_${item.name}`}
                        className="px-2.5 py-1.5 bg-[#FAF9F6] hover:bg-[#1C1917] text-[#1C1917] hover:text-white border border-[#E7E5E4] text-xs font-bold rounded-xl transition-colors cursor-pointer whitespace-nowrap"
                      >
                        메인 추천
                      </button>
                      <button
                        type="button"
                        onClick={() => onOpenEditIngredient(item)}
                        data-key={`edit_ingredient_${item.name}`}
                        className="p-2 text-[#78716C] hover:text-[#1C1917] rounded-lg hover:bg-[#F5F5F4] transition-colors cursor-pointer"
                        title="재료 수정"
                        aria-label={`${item.name} 수정`}
                      >
                        <Edit2 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={() => setDeletingItem(item)}
                        data-key={`delete_ingredient_${item.name}`}
                        className="p-2 text-[#78716C] hover:text-[#DC2626] hover:bg-[#FEF2F2] rounded-lg transition-colors cursor-pointer"
                        title="재료 삭제"
                        aria-label={`${item.name} 삭제`}
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* 5. Kitchen Seasoning Rack Checklist */}
        <section className="bg-white border border-[#E7E5E4] rounded-2xl p-5 space-y-3">
          <div>
            <h3 className="text-sm font-extrabold text-[#1C1917]">
              내 주방 기본 양념 & 조미료 설정
            </h3>
            <p className="text-xs text-[#78716C] mt-0.5">
              보유 중인 기본 양념을 선택해 두면 사진을 찍지 않아도 요리 추천에 자동 반영됩니다.
            </p>
          </div>

          <div className="flex flex-wrap gap-2 pt-1">
            {IngredientNormalizer.defaultSeasonings.map((seasoning) => {
              const isOwned = ownedSeasonings.has(seasoning);
              return (
                <button
                  type="button"
                  key={seasoning}
                  onClick={() => toggleSeasoning(seasoning)}
                  data-key={`seasoning_chip_${seasoning}`}
                  className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all cursor-pointer border whitespace-nowrap ${
                    isOwned
                      ? 'bg-[#1C1917] border-[#1C1917] text-white'
                      : 'bg-[#FAF9F6] border-[#E7E5E4] text-[#78716C] hover:border-[#A8A29E]'
                  }`}
                >
                  {seasoning}
                  {isOwned && ' ✓'}
                </button>
              );
            })}
          </div>
        </section>
      </div>

      {/* Delete Confirmation Dialog */}
      {deletingItem && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-xs">
          <div className="bg-white w-full max-w-xs rounded-2xl p-5 shadow-2xl border border-[#E7E5E4] space-y-4">
            <h3 className="text-base font-extrabold text-[#1C1917]">
              식재료 삭제 확인
            </h3>
            <p className="text-xs text-[#78716C] leading-relaxed">
              '{deletingItem.name}'을(를) 내 냉장고 목록에서 삭제할까요?
            </p>
            <div className="flex items-center justify-end gap-2 pt-1">
              <button
                type="button"
                onClick={() => setDeletingItem(null)}
                className="px-4 py-2 rounded-xl text-xs font-bold text-[#78716C] hover:bg-[#F5F5F4] transition-colors cursor-pointer"
              >
                취소
              </button>
              <button
                type="button"
                onClick={() => {
                  removeIngredient(deletingItem.id);
                  setDeletingItem(null);
                }}
                className="px-4 py-2 rounded-xl text-xs font-bold bg-[#DC2626] hover:bg-red-700 text-white transition-colors cursor-pointer"
              >
                삭제
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
