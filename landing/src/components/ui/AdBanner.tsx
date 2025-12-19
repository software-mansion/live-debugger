import React, { useEffect, useState, useRef } from "react";

export interface AdBannerProps {
  zoneId: string;
  contentId: string;
}

export const AdBanner = ({ zoneId, contentId }: AdBannerProps) => {
  const [isAdLoaded, setIsAdLoaded] = useState(false);
  const adContainerRef = useRef<HTMLDivElement>(null);
  const adContentRef = useRef<HTMLDivElement>(null);
  const adDetectedRef = useRef(false);

  useEffect(() => {
    const adContainer = adContainerRef.current;
    if (!adContainer) return;

    const insElement = adContainer.querySelector("ins");
    if (!insElement) return;

    const checkForAd = () => {
      if (adDetectedRef.current) return true;

      const isLoaded =
        insElement.getAttribute("data-content-loaded") === "1" ||
        insElement.querySelector(".revive-banner") !== null ||
        insElement.querySelector("a.revive-banner") !== null ||
        (insElement.children.length > 0 && insElement.offsetHeight > 10);

      if (isLoaded) {
        adDetectedRef.current = true;
        setIsAdLoaded(true);
        return true;
      }
      return false;
    };

    const observer = new MutationObserver(() => {
      checkForAd();
    });

    observer.observe(insElement, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ["data-content-loaded", "style", "class", "id"],
    });

    observer.observe(adContainer, {
      childList: true,
      subtree: true,
      attributes: true,
    });

    const handleAdLoaded = () => {
      if (!adDetectedRef.current) {
        adDetectedRef.current = true;
        setIsAdLoaded(true);
      }
    };

    const eventName = `content-${contentId}-loaded`;
    document.addEventListener(eventName, handleAdLoaded);

    checkForAd();

    const intervals = [
      setTimeout(checkForAd, 500),
      setTimeout(checkForAd, 1000),
      setTimeout(checkForAd, 2000),
      setTimeout(checkForAd, 3000),
      setTimeout(checkForAd, 5000),
    ];

    return () => {
      observer.disconnect();
      intervals.forEach(clearTimeout);
      document.removeEventListener(eventName, handleAdLoaded);
    };
  }, [contentId]);

  useEffect(() => {
    const container = adContainerRef.current;
    const content = adContentRef.current;
    if (!container || !content) return;

    if (isAdLoaded) {
      const updateHeight = () => {
        const height = content.scrollHeight || content.offsetHeight || 100;
        container.style.maxHeight = `${Math.max(height, 100)}px`;
        container.style.overflow = "visible";
      };
      requestAnimationFrame(updateHeight);
      setTimeout(updateHeight, 100);
      setTimeout(updateHeight, 500);
    } else {
      container.style.maxHeight = "0px";
      container.style.overflow = "hidden";
    }
  }, [isAdLoaded]);

  return (
    <div
      ref={adContainerRef}
      className="w-full transition-all duration-500 ease-in-out"
      style={{
        opacity: isAdLoaded ? 1 : 0,
      }}
    >
      <div ref={adContentRef} className="w-full">
        <ins data-content-zoneid={zoneId} data-content-id={contentId}></ins>
      </div>
      <script
        async
        src="//revive-adserver.swmansion.com/www/assets/js/lib.js"
      ></script>
    </div>
  );
};
