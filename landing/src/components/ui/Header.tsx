import React, { useEffect, useState, useRef, useImperativeHandle } from "react";
import { cn } from "@/lib/utils";
import { Logo } from "@/components/ui/Logo";
import { Github } from "@/components/ui/Github";
import { AdBanner } from "@/components/ui/AdBanner";
import { getStorageValue } from "@/lib/utils";

export interface HeaderProps extends React.HTMLAttributes<HTMLElement> {}

const DEFAULT_LATEST_NEWS_ID = "v0.5.0";
const GITHUB_API_URL =
  "https://api.github.com/repos/software-mansion/live-debugger/releases/latest";

const navItems = [
  { name: "Features", href: "#features" },
  { name: "Getting started", href: "#gettingstarted" },
  { name: "What's new", href: "#whatsnew" },
  { name: "Roadmap", href: "#roadmap" },
];

const sectionThemes = [
  { id: "hero", theme: "dark" },
  { id: "features", theme: "light" },
  { id: "videosection", theme: "dark" },
  { id: "debugcases", theme: "light" },
  { id: "gettingstarted", theme: "light" },
  { id: "whatsnew", theme: "light" },
  { id: "roadmap", theme: "light" },
  { id: "footer", theme: "dark" },
];

const Indicator = ({ isVisible }: { isVisible: boolean }) => (
  <div
    className={`-mt-2 pl-1 transition-opacity duration-300 ease-in-out ${
      isVisible ? "opacity-100" : "opacity-0"
    }`}
  >
    <span className="relative flex h-1.5 w-1.5">
      <span className="animate-pulse-red bg-swm-red-100 absolute inline-flex h-full w-full rounded-full opacity-75"></span>
      <span className="bg-swm-red-100 relative inline-flex h-1.5 w-1.5 rounded-full"></span>
    </span>
  </div>
);

const Header = React.forwardRef<HTMLElement, HeaderProps>(
  ({ className, ...props }, ref) => {
    const [isScrolled, setIsScrolled] = useState(false);
    const [showIndicator, setShowIndicator] = useState(false);
    const [activeTheme, setActiveTheme] = useState("dark");
    const [latestNewsId, setLatestNewsId] = useState(DEFAULT_LATEST_NEWS_ID);
    const [bannerHeight, setBannerHeight] = useState(0);

    const localHeaderRef = useRef<HTMLElement>(null);
    useImperativeHandle(ref, () => localHeaderRef.current!);

    useEffect(() => {
      const fetchLatestRelease = async () => {
        try {
          const response = await fetch(GITHUB_API_URL);
          if (response.ok) {
            const data = await response.json();
            if (data.tag_name) {
              setLatestNewsId(data.tag_name);
            }
          }
        } catch (error) {
          console.error("Failed to fetch latest release:", error);
        }
      };

      fetchLatestRelease();
    }, []);

    useEffect(() => {
      const seenVersion = getStorageValue("seenNewsVersion", null);
      setShowIndicator(seenVersion !== latestNewsId);
    }, [latestNewsId]);

    useEffect(() => {
      const handleScroll = () => {
        const scrollY = window.scrollY;
        setIsScrolled(scrollY > 10);

        const headerHeight = localHeaderRef.current?.offsetHeight || 0;
        const triggerPoint = scrollY + headerHeight / 2;

        let currentTheme = "dark";
        for (let i = sectionThemes.length - 1; i >= 0; i--) {
          const section = sectionThemes[i];
          const element = document.getElementById(section.id);

          if (element) {
            if (triggerPoint >= element.offsetTop) {
              currentTheme = section.theme;
              break;
            }
          }
        }
        setActiveTheme(currentTheme);
      };

      handleScroll();
      window.addEventListener("scroll", handleScroll);

      return () => {
        window.removeEventListener("scroll", handleScroll);
      };
    }, []);

    return (
      <header
        ref={localHeaderRef}
        className={cn(
          "sticky top-0 z-50 w-full transition-all duration-500 ease-in-out",
          activeTheme === "dark"
            ? "bg-primary text-primary-foreground"
            : "text-primary bg-white",
          isScrolled
            ? activeTheme === "dark"
              ? "border-b border-white/40"
              : "border-b border-black/10"
            : "border-b border-transparent",
          className,
        )}
        style={{
          transform:
            bannerHeight > 0 ? `translateY(${bannerHeight}px)` : undefined,
        }}
        {...props}
      >
        <AdBanner
          zoneId="3"
          contentId="ea15c4216158c4097b65fe6504a4b3b7"
          setBannerHeight={setBannerHeight}
        />
        <div className="mx-auto flex h-20 w-full max-w-[1360px] items-center justify-between px-7 sm:px-8">
          <a href="#hero" className="mr-6 flex items-center gap-2">
            <Logo className="size-36 sm:size-42 md:size-45" />
          </a>

          <nav className="mx-auto hidden items-center justify-center gap-10 md:flex">
            {navItems.map((item) => (
              <a
                key={item.name}
                href={item.href}
                className={cn(
                  "font-aeonik text-md justify-center font-light",
                  "transition-all hover:scale-105",
                  activeTheme === "dark"
                    ? "hover:text-slate-300"
                    : "hover:text-primary/70",
                  "last:hidden",
                  "lg:last:block",
                )}
                onClick={() => {
                  if (item.href === "#whatsnew") {
                    setShowIndicator(false);
                    try {
                      localStorage.setItem("seenNewsVersion", latestNewsId);
                    } catch (error) {
                      console.error("Error setting localStorage", error);
                    }
                  }
                }}
              >
                <div className="flex items-center justify-center gap-1">
                  {item.name}
                  {item.href === "#whatsnew" && (
                    <Indicator isVisible={showIndicator} />
                  )}
                </div>
              </a>
            ))}
          </nav>

          <div className="flex items-center gap-5 sm:gap-10">
            <a
              href="https://hexdocs.pm/live_debugger/welcome.html"
              target="_blank"
              rel="noopener noreferrer"
              className={cn(
                "font-aeonik text-md font-light",
                activeTheme === "dark"
                  ? "hover:text-slate-300"
                  : "hover:text-primary/70",
              )}
            >
              Docs
            </a>
            <a
              href="https://github.com/software-mansion/live-debugger"
              target="_blank"
              rel="noopener noreferrer"
              className={cn(
                activeTheme === "dark"
                  ? "hover:text-slate-300"
                  : "hover:text-primary/70",
              )}
            >
              <Github className="size-6 sm:size-7 md:size-8" />
              <span className="sr-only">GitHub</span>
            </a>
          </div>
        </div>
      </header>
    );
  },
);

Header.displayName = "Header";

export { Header };
