import React, { useState } from 'react';
import { Camera } from 'lucide-react';
import { Ingredient, RecommendedRecipe } from './types';
import { useApp } from './context/AppContext';
import { PantryView } from './views/PantryView';
import { RecommendationsView } from './views/RecommendationsView';
import { SavedAndPreferencesView } from './views/SavedAndPreferencesView';
import { Navbar } from './components/Navbar';
import { RecipeDetailModal } from './components/RecipeDetailModal';
import { IngredientEditorModal } from './components/IngredientEditorModal';
import { ScannerModal } from './components/ScannerModal';
import { AllergySettingsModal } from './components/AllergySettingsModal';

export const App: React.FC = () => {
  const {
    bookmarkedRecipeIds,
    preferences,
    addOrUpdateIngredient,
    updatePreferences,
  } = useApp();

  const [activeTab, setActiveTab] = useState<'pantry' | 'recommendations' | 'saved'>('pantry');
  const [isScannerOpen, setIsScannerOpen] = useState(false);
  const [selectedRecipeDetail, setSelectedRecipeDetail] = useState<RecommendedRecipe | null>(null);
  const [isManualAddOpen, setIsManualAddOpen] = useState(false);
  const [editingIngredient, setEditingIngredient] = useState<Ingredient | null>(null);
  const [isAllergySettingsOpen, setIsAllergySettingsOpen] = useState(false);

  const handleFinishScan = () => {
    setIsScannerOpen(false);
    setActiveTab('recommendations');
  };

  return (
    <div className="min-h-screen bg-[#FAF9F6] text-[#1C1917] flex flex-col font-sans">
      {/* Active Tab View */}
      <main className="flex-1">
        {activeTab === 'pantry' && (
          <PantryView
            onStartScan={() => setIsScannerOpen(true)}
            onGoToRecommendations={() => setActiveTab('recommendations')}
            onOpenManualAdd={() => setIsManualAddOpen(true)}
            onOpenEditIngredient={(item) => setEditingIngredient(item)}
            onSelectRecipeDetail={(recipe) => setSelectedRecipeDetail(recipe)}
          />
        )}

        {activeTab === 'recommendations' && (
          <RecommendationsView
            onOpenScanner={() => setIsScannerOpen(true)}
            onOpenAllergySettings={() => setIsAllergySettingsOpen(true)}
            onSelectRecipeDetail={(recipe) => setSelectedRecipeDetail(recipe)}
          />
        )}

        {activeTab === 'saved' && (
          <SavedAndPreferencesView
            onOpenAllergySettings={() => setIsAllergySettingsOpen(true)}
            onSelectRecipeDetail={(recipe) => setSelectedRecipeDetail(recipe)}
          />
        )}
      </main>

      {/* Floating Action Button for Pantry Tab */}
      {activeTab === 'pantry' && (
        <button
          type="button"
          onClick={() => setIsScannerOpen(true)}
          data-key="fab_scan_fridge"
          className="fixed bottom-20 right-5 z-30 flex items-center gap-2 bg-[#1C1917] hover:bg-[#292524] text-white px-4 py-3 rounded-2xl shadow-lg transition-all active:scale-95 cursor-pointer border border-white/10"
        >
          <Camera className="w-5 h-5 text-[#4ADE80]" />
          <span className="text-xs font-extrabold tracking-tight whitespace-nowrap">냉장고 스캔</span>
        </button>
      )}

      {/* Bottom 3-Tab Navbar */}
      <Navbar
        activeTab={activeTab}
        onSelectTab={setActiveTab}
        savedCount={bookmarkedRecipeIds.size}
      />

      {/* Modals & Dialogs */}
      {isScannerOpen && (
        <ScannerModal
          onClose={() => setIsScannerOpen(false)}
          onFinishScan={handleFinishScan}
        />
      )}

      {selectedRecipeDetail && (
        <RecipeDetailModal
          recommendedRecipe={selectedRecipeDetail}
          onClose={() => setSelectedRecipeDetail(null)}
        />
      )}

      {isManualAddOpen && (
        <IngredientEditorModal
          onSave={(item) => addOrUpdateIngredient(item)}
          onClose={() => setIsManualAddOpen(false)}
        />
      )}

      {editingIngredient && (
        <IngredientEditorModal
          initialIngredient={editingIngredient}
          onSave={(item) => {
            addOrUpdateIngredient(item);
            setEditingIngredient(null);
          }}
          onClose={() => setEditingIngredient(null)}
        />
      )}

      {isAllergySettingsOpen && (
        <AllergySettingsModal
          preferences={preferences}
          onUpdate={updatePreferences}
          onClose={() => setIsAllergySettingsOpen(false)}
        />
      )}
    </div>
  );
};
