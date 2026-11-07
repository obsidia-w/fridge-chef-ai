import React from 'react';
import { Camera, Plus, Search, Sparkles } from 'lucide-react';

interface HeaderProps {
  ingredientCount: number;
  canMakeNowCount: number;
  onOpenManualAdd: () => void;
  onStartScan: () => void;
  onGoToRecommendations: () => void;
}

export const Header: React.FC<HeaderProps> = ({
  ingredientCount,
  canMakeNowCount,
  onOpenManualAdd,
  onStartScan,
  onGoToRecommendations,
}) => {
  return (
    <div className="bg-white border-b border-[#E7E5E4]">
      {/* Top Navigation Bar */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 py-4 flex items-center justify-between gap-4">
        <div className="flex items-center gap-2.5 shrink-0">
          <div className="w-9 h-9 rounded-xl bg-[#1C1917] text-white flex items-center justify-center font-extrabold text-sm tracking-tight">
            셰프
          </div>
          <h1 className="text-lg sm:text-xl font-extrabold tracking-tight text-[#1C1917] whitespace-nowrap">
            냉장고 셰프 AI
          </h1>
        </div>

        <div className="flex items-center gap-2 shrink-0">
          <button
            type="button"
            onClick={onOpenManualAdd}
            data-key="pantry_manual_add_button"
            className="flex items-center gap-1.5 bg-[#FAF9F6] hover:bg-[#F5F5F4] border border-[#E7E5E4] text-[#1C1917] text-xs font-bold px-3.5 py-2.5 rounded-xl transition-colors cursor-pointer whitespace-nowrap"
          >
            <Plus className="w-4 h-4 text-[#15803D]" />
            <span>재료 직접 추가</span>
          </button>

          <button
            type="button"
            onClick={onStartScan}
            aria-label="카메라로 스캔"
            className="flex items-center gap-1.5 bg-[#1C1917] hover:bg-[#292524] text-white text-xs font-bold px-3.5 py-2.5 rounded-xl transition-colors cursor-pointer whitespace-nowrap"
          >
            <Camera className="w-4 h-4 text-[#4ADE80]" />
            <span className="hidden sm:inline">AI 스캔</span>
          </button>
        </div>
      </div>

      {/* Unified Editorial Hero Banner */}
      <div className="max-w-5xl mx-auto px-4 sm:px-6 pb-6 pt-1">
        <div className="bg-[#1C1917] text-white rounded-3xl p-5 sm:p-7 flex flex-col md:flex-row md:items-center md:justify-between gap-5">
          <div className="space-y-2 max-w-xl">
            <div className="inline-flex items-center gap-1.5 text-xs font-bold text-[#4ADE80] tracking-tight">
              <Sparkles className="w-3.5 h-3.5" />
              <span>4구역 비전 + 한글 라벨 OCR 식재료 인식</span>
            </div>
            <h2 className="text-xl sm:text-2xl font-extrabold tracking-tight text-white leading-snug text-balance">
              냉장고 속 재료로 오늘 바로 만들 수 있는 요리를 찾아보세요
            </h2>
            <p className="text-xs sm:text-sm text-[#A8A29E] tabular-nums">
              현재 보유 재료 <strong className="text-white font-bold">{ingredientCount}개</strong> · 지금 바로 조리 가능 <strong className="text-[#4ADE80] font-bold">{canMakeNowCount}개</strong>
            </p>
          </div>

          <div className="flex flex-wrap sm:flex-nowrap items-center gap-2.5 shrink-0">
            <button
              type="button"
              onClick={onStartScan}
              data-key="hero_start_scan_button"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-2 bg-[#15803D] hover:bg-[#166534] text-white text-xs sm:text-sm font-bold py-3 px-4 rounded-xl transition-colors cursor-pointer whitespace-nowrap"
            >
              <Camera className="w-4 h-4 shrink-0" />
              <span>카메라로 재료 인식</span>
            </button>
            <button
              type="button"
              onClick={onGoToRecommendations}
              data-key="hero_view_recommendations_button"
              className="flex-1 sm:flex-initial flex items-center justify-center gap-1.5 bg-white/10 hover:bg-white/15 border border-white/15 text-white text-xs sm:text-sm font-bold py-3 px-4 rounded-xl transition-colors cursor-pointer whitespace-nowrap"
            >
              <Search className="w-4 h-4 shrink-0 text-[#A8A29E]" />
              <span>추천 요리 보기</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
