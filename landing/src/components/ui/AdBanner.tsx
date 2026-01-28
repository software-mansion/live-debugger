import React, { useEffect, useRef, useState } from "react";

const MIN_VISIBLE_HEIGHT = 5;

export interface AdBannerProps {
  zoneId: string;
  contentId: string;
  setBannerHeight?: (height: number) => void;
}

export const AdBanner = ({
  zoneId,
  contentId,
  setBannerHeight,
}: AdBannerProps) => {
  const containerRef = useRef<HTMLDivElement>(null);
  const contentRef = useRef<HTMLDivElement>(null);
  const insRef = useRef<HTMLModElement | null>(null);

  const [hasBanner, setHasBanner] = useState(false);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const getIns = () => {
      const current = container.querySelector("ins");
      if (current && current !== insRef.current) {
        insRef.current = current as HTMLModElement;
      }
      return insRef.current;
    };

    const detectBanner = () => {
      const ins = getIns();
      if (!ins) return false;
      const hasChildren = ins.children.length > 0;
      const height = ins.offsetHeight;
      const hasVisible = height >= MIN_VISIBLE_HEIGHT;
      return hasChildren && hasVisible;
    };

    const updateState = () => {
      setHasBanner(detectBanner());
    };

    // container observer
    const containerObserver = new MutationObserver(updateState);
    containerObserver.observe(container, {
      childList: true,
      subtree: true,
      attributes: true,
    });

    // content observer
    const ins = getIns();
    let insObserver: MutationObserver | null = null;
    if (ins) {
      insObserver = new MutationObserver(updateState);
      insObserver.observe(ins, {
        childList: true,
        subtree: true,
        attributes: true,
        attributeFilter: ["data-content-loaded", "style", "class", "id"],
      });
    }

    updateState();

    return () => {
      containerObserver.disconnect();
      if (insObserver) insObserver.disconnect();
    };
  }, [contentId]);

  // measure height and trigger animation
  useEffect(() => {
    const container = containerRef.current;
    const content = contentRef.current;
    if (!container || !content) return;

    if (!hasBanner) {
      container.style.height = "0px";
      container.style.overflow = "hidden";
      setBannerHeight?.(0);
      document.documentElement.dataset.bannerLoaded = "false";
      return;
    }

    requestAnimationFrame(() => {
      const measuredHeight = Math.max(
        content.scrollHeight,
        content.offsetHeight,
      );

      container.style.height = `${measuredHeight}px`;
      container.style.overflow = "visible";
      setBannerHeight?.(measuredHeight);
      document.documentElement.dataset.bannerLoaded = "true";
    });
  }, [hasBanner, setBannerHeight]);

  return (
    <div
      ref={containerRef}
      className="absolute top-0 left-0 w-full transition-all duration-500 ease-in-out"
      style={{
        opacity: hasBanner ? 1 : 0,
        height: hasBanner ? undefined : "0px",
        overflow: hasBanner ? "visible" : "hidden",
        transform: "translateY(-100%)",
      }}
    >
      <div ref={contentRef} className="w-full" suppressHydrationWarning>
        <ins
          data-content-zoneid={zoneId}
          data-content-id={contentId}
          className="block"
          suppressHydrationWarning
        />
      </div>
      <script
        async
        src="//revive-adserver.swmansion.com/www/assets/js/lib.js"
      />
    </div>
  );
};
