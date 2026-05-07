# Assets

Two separate JS/CSS bundles. They run in different places and serve different purposes.

## Layout

```text
assets/
├── app/        # the LiveDebugger UI itself (served at the debugger endpoint)
└── client/     # injected into the *debugged* application's pages
```

Each is its own npm package with its own `package.json`, `node_modules`, and entry point.
They are bundled independently by esbuild via the LiveDebugger mix tasks.

| | `app/` | `client/` |
| --- | --- | --- |
| Loaded by | `app/web/layout.ex` | A meta-tag injected by LiveDebugger |
| Includes Tailwind | Yes (v4) | No (scoped CSS only - must not leak into the host app) |

## App

JS and CSS for the LiveDebugger UI. Uses Tailwind v4.

`app.js` is the entrypoint of the application.
All non-hook JS logic goes there.

### Light / dark mode

Themes are defined as CSS variables in `app/styles/themes/`.

To add a new color:

1. Add the variable to **both** `themes/light.css` and `themes/dark.css`.
2. Add a Tailwind color mapping in `tailwind.config.js` pointing at `var(--your-var)`.

## Client

A tiny bundle injected into the **debugged** application's pages. It is responsible for gathering information, rendering LiveDebugger overlays, tooltips and debug button. Styles are scoped (use prefix for classes) to ensure nothing leaks into the host page.

### How it communicates with LiveDebugger

LiveDebugger injects a meta tag into every page of the debugged app (part of installation process). It allows creation of separate Phoenix socket which communicates with LiveDebugger.

Once joined, communication is bidirectional over the channel.
