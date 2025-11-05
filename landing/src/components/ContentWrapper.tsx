import React from "react";

const ContentWrapper: React.FC<{
  className?: string;
  children: React.ReactNode;
}> = ({ children, className = "" }) => {
  return (
    <div
      className={`mx-auto flex w-full max-w-[552px] items-center justify-center max-sm:px-8 sm:w-[552px] sm:max-w-[552px] md:w-[936px] md:max-w-[936px] lg:w-[1360px] lg:max-w-[1360px] ${className} `}
    >
      {children}
    </div>
  );
};

export default ContentWrapper;
