// @ts-check
import { defineConfig, envField } from "astro/config";
import react from "@astrojs/react";
import tailwindcss from "@tailwindcss/vite";

// https://astro.build/config
export default defineConfig({
  integrations: [react()],
  env: {
    schema: {
      ENABLE_ANALYTICS: envField.string({
        access: "public",
        context: "server",
        default: "false",
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
        provider: "local",
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
    ],
  },
});
