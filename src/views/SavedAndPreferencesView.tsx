import React from 'react';
import { Settings, Bookmark, Globe, ChevronRight } from 'lucide-react';
import { CUISINE_DEFINITIONS, CuisineCategory, RecommendedRecipe } from '../types';
import { useApp } from '../context/AppContext';
import { RecipeImage } from '../components/RecipeImage';

interface SavedAndPreferencesViewProps {
  onOpenAllergySettings: () => void;
  onSelectRecipeDetail: (recipe: RecommendedRecipe) => void;
}

export const SavedAndPreferencesView: React.FC<SavedAndPreferencesViewProps> = ({
  onOpenAllergySettings,
  onSelectRecipeDetail,
}) => {
  const { allRecipes, bookmarkedRecipeIds, preferences, recommendations } = useApp();

  const bookmarkedRecipes = allRecipes.filter((r) =>
    bookmarkedRecipeIds.has(r.id)
  );

  return (
    <div className="min-h-screen bg-[#FAF9F6] pb-28">
      {/* Top Bar */}
      <header className="sticky top-0 z-20 bg-white/95 backdrop-blur-md border-b border-[#E7E5E4] px-4 sm:px-6 py-3.5">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <h1 className="text-lg font-extrabold text-[#1C1917] tracking-tight">
            저장한 요리 & 설정
          </h1>

          <button
            type="button"
            onClick={onOpenAllergySettings}
            data-key="open_settings_modal_button"
            className="flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-[#1C1917] text-white text-xs font-bold hover:bg-[#292524] transition-colors cursor-pointer"
          >
            <Settings className="w-4 h-4" />
            <span className="tabular-nums">
              {preferences.allergens.length === 0
                ? '알레르기 설정'
                : `알레르기 설정 (${preferences.allergens.length})`}
            </span>
          </button>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-6 space-y-6">
        {/* Bookmarked Recipes Section */}
        <div className="space-y-3.5">
          <h2 className="text-base font-extrabold text-[#1C1917] tabular-nums">
            저장한 레시피 ({bookmarkedRecipes.length})
          </h2>

          {bookmarkedRecipes.length === 0 ? (
            <div className="p-6 bg-white rounded-2xl border border-[#E7E5E4] flex items-center gap-4">
              <div className="w-11 h-11 rounded-xl bg-[#F5F5F4] text-[#1C1917] flex items-center justify-center shrink-0">
                <Bookmark className="w-5 h-5" />
              </div>
              <p className="text-xs text-[#78716C] leading-relaxed">
                아직 저장한 레시피가 없습니다. 마음에 드는 요리 상세 화면에서 하트 아이콘을 눌러 저장해 보세요.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3.5">
              {bookmarkedRecipes.map((recipe) => {
                const matchingRec = recommendations.find((r) => r.recipe.id === recipe.id);
                const resolvedRec: RecommendedRecipe = matchingRec || {
                  recipe,
                  tier: 'canMakeNow',
                  matchedIngredients: recipe.ingredients
                    .filter((i) => !i.isSeasoning)
                    .map((e) => e.name),
                  missingCoreIngredients: [],
                  missingSeasonings: [],
                  availableSubstitutes: {},
                  pantryUtilizationRatio: 1.0,
                  hasUncertainQuantities: false,
                  usesSelectedMainIngredient: false,
                  recommendationReason: '저장해 둔 즐겨찾기 레시피입니다.',
                  utilizationPercentage: 100,
                };

                return (
                  <button
                    type="button"
                    key={recipe.id}
                    onClick={() => onSelectRecipeDetail(resolvedRec)}
                    className="group w-full text-left p-3.5 bg-white rounded-2xl border border-[#E7E5E4] hover:border-[#1C1917]/50 transition-all cursor-pointer flex items-center justify-between"
                  >
                    <div className="flex items-center gap-3.5 min-w-0">
                      <div className="w-16 h-16 rounded-xl overflow-hidden bg-[#F5F5F4] shrink-0">
                        <RecipeImage
                          src={recipe.imageUrl}
                          alt={recipe.title}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      </div>

                      <div className="min-w-0 space-y-1">
                        <h3 className="text-sm font-extrabold text-[#1C1917] truncate">
                          {recipe.title}
                        </h3>
                        <p className="text-xs text-[#78716C] tabular-nums">
                          {recipe.category} · {recipe.nutritionPerServing.caloriesKcal} kcal · {recipe.cookingTimeMinutes}분
                        </p>
                      </div>
                    </div>

                    <ChevronRight className="w-4 h-4 text-[#78716C] shrink-0 ml-2" />
                  </button>
                );
              })}
            </div>
          )}
        </div>

        {/* Global Recipe Sources Reference Card */}
        <div className="p-5 bg-white rounded-2xl border border-[#E7E5E4] space-y-3">
          <div className="flex items-center gap-2 text-[#1C1917]">
            <Globe className="w-4 h-4 text-[#15803D]" />
            <h2 className="text-sm font-extrabold text-[#1C1917]">
              카테고리별 글로벌 레시피 출처 안내
            </h2>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-[#78716C]">
            {(Object.keys(CUISINE_DEFINITIONS) as CuisineCategory[])
              .filter((c) => c !== 'all')
              .map((cKey) => {
                const c = CUISINE_DEFINITIONS[cKey];
                return (
                  <p key={cKey}>
                    <strong className="text-[#1C1917]">{c.label}</strong> · {c.primarySourceSite}
                  </p>
                );
              })}
          </div>
        </div>
      </div>
    </div>
  );
};
