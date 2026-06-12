import type { BannerZone } from "./shared";

export const TOP_BAR_BANNER = {
  rotateIntervalMs: 4000,
  hiddenPaths: [] as string[],
  zones: [
    {
      zoneId: "live-debugger-topbar-1",
      contentId: "ea15c4216158c4097b65fe6504a4b3b7",
      fallbackBgColor: "#001a72",
    },
    {
      zoneId: "live-debugger-topbar-2",
      contentId: "ea15c4216158c4097b65fe6504a4b3b7",
      fallbackBgColor: "#001a72",
    },
    {
      zoneId: "live-debugger-topbar-3",
      contentId: "ea15c4216158c4097b65fe6504a4b3b7",
      fallbackBgColor: "#001a72",
    },
  ] satisfies BannerZone[],
};
