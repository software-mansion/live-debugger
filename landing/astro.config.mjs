// @ts-check
import { defineConfig, envField, fontProviders } from "astro/config";
import swmGeo from "./swm-geo.mjs";
import react from "@astrojs/react";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  integrations: [
    swmGeo({ name: "LiveDebugger", description: "LiveView debugging made simple", repository: "live-debugger" }),react()],
  env: {
    schema: {
      ENABLE_ANALYTICS: envField.string({
        access: "public",
        context: "server",
        default: "false",
        optional: true,
      }),
      YOUTUBE_API_KEY: envField.string({
        access: "public",
        context: "server",
        default: "",
        optional: true,
      }),
    },
  },
  vite: {
    plugins: [tailwindcss()],
  },
  site: "https://docs.swmansion.com",
  base: "/live-debugger",
  experimental: {
    fonts: [
      {
        cssVariable: "--font-aeonik",
        name: "Aeonik",
        provider: fontProviders.local(),
        options: {
          variants: [
            {
              src: ["./public/fonts/aeonik/aeonik-light.otf"],
              style: "normal",
              weight: 300,
            },
            {
              src: ["./public/fonts/aeonik/aeonik-regular.otf"],
              style: "normal",
              weight: 400,
            },
            {
              src: ["./public/fonts/aeonik/aeonik-medium.otf"],
              style: "normal",
              weight: 600,
            },
          ],
        },
      },
    ],
  },
});
