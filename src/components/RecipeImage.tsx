import React, { useState } from 'react';
import { Utensils } from 'lucide-react';

interface RecipeImageProps {
  src: string;
  alt: string;
  className?: string;
}

export const RecipeImage: React.FC<RecipeImageProps> = ({
  src,
  alt,
  className = 'w-full h-full object-cover',
}) => {
  const [hasError, setHasError] = useState(false);

  if (hasError || !src) {
    return (
      <div
        className={`flex flex-col items-center justify-center bg-[#F5F5F4] text-[#78716C] p-3 text-center ${className}`}
      >
        <Utensils className="w-6 h-6 mb-1 text-[#A8A29E]" />
        <span className="text-[11px] font-semibold line-clamp-1">{alt}</span>
      </div>
    );
  }

  return (
    <img
      src={src}
      alt={alt}
      referrerPolicy="no-referrer"
      loading="lazy"
      onError={() => setHasError(true)}
      className={className}
    />
  );
};
