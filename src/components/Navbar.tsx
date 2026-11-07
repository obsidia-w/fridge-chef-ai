import React from 'react';
import { Refrigerator, UtensilsCrossed, Bookmark } from 'lucide-react';

interface NavbarProps {
  activeTab: 'pantry' | 'recommendations' | 'saved';
  onSelectTab: (tab: 'pantry' | 'recommendations' | 'saved') => void;
  savedCount: number;
}

export const Navbar: React.FC<NavbarProps> = ({
  activeTab,
  onSelectTab,
  savedCount,
}) => {
  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-[#E7E5E4] px-4 py-2">
      <div className="max-w-5xl mx-auto flex items-center justify-around">
        <button
          type="button"
          onClick={() => onSelectTab('pantry')}
          data-key="nav_pantry"
          className={`flex flex-col items-center justify-center py-1 px-4 rounded-xl transition-all cursor-pointer ${
            activeTab === 'pantry'
              ? 'text-[#1C1917] font-extrabold'
              : 'text-[#78716C] hover:text-[#1C1917] font-medium'
          }`}
        >
          <div
            className={`p-1.5 rounded-xl transition-colors ${
              activeTab === 'pantry' ? 'bg-[#F5F5F4]' : 'bg-transparent'
            }`}
          >
            <Refrigerator className="w-5 h-5" />
          </div>
          <span className="text-xs mt-0.5 whitespace-nowrap">내 냉장고</span>
        </button>

        <button
          type="button"
          onClick={() => onSelectTab('recommendations')}
          data-key="nav_recommendations"
          className={`flex flex-col items-center justify-center py-1 px-4 rounded-xl transition-all cursor-pointer ${
            activeTab === 'recommendations'
              ? 'text-[#1C1917] font-extrabold'
              : 'text-[#78716C] hover:text-[#1C1917] font-medium'
          }`}
        >
          <div
            className={`p-1.5 rounded-xl transition-colors ${
              activeTab === 'recommendations' ? 'bg-[#F5F5F4]' : 'bg-transparent'
            }`}
          >
            <UtensilsCrossed className="w-5 h-5" />
          </div>
          <span className="text-xs mt-0.5 whitespace-nowrap">맞춤 요리 추천</span>
        </button>

        <button
          type="button"
          onClick={() => onSelectTab('saved')}
          data-key="nav_saved_prefs"
          className={`relative flex flex-col items-center justify-center py-1 px-4 rounded-xl transition-all cursor-pointer ${
            activeTab === 'saved'
              ? 'text-[#1C1917] font-extrabold'
              : 'text-[#78716C] hover:text-[#1C1917] font-medium'
          }`}
        >
          <div
            className={`p-1.5 rounded-xl transition-colors ${
              activeTab === 'saved' ? 'bg-[#F5F5F4]' : 'bg-transparent'
            }`}
          >
            <Bookmark className="w-5 h-5" />
          </div>
          <span className="text-xs mt-0.5 whitespace-nowrap">저장 & 설정</span>
          {savedCount > 0 && (
            <span className="absolute top-1 right-5 w-4 h-4 rounded-full bg-[#15803D] text-white text-[10px] font-bold flex items-center justify-center tabular-nums">
              {savedCount}
            </span>
          )}
        </button>
      </div>
    </nav>
  );
};
