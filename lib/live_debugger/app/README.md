# App

LiveView UI application. It follows some predefined conventions.

## File / folder structure

Each page's elements are nested in subfolders (e.g. a nested LiveView lives in a subfolder of the parent LiveView).
Components shared between pages or larger UI parts go in the nearest common ancestor folder.

Each **feature** - a page or larger UI element (`debugger/`, `discovery/`, `settings/`) - follows the same internal layout:

```text
<feature>/
├── actions.ex             # side-effecting operations (write to settings, dispatch events)
├── queries.ex             # read-only lookups
├── events.ex              # events the feature publishes
├── <nested feature>/
    ├── ...
└── web/
    ├── <feature>_live.ex  # the LiveView entry point
    ├── components/
    ├── live_components/
    ├── hooks/             # feature-specific hooks (see below)
    └── hook_components/   # function components that register their own hooks (see below)
```

Not all folders are necessary - if there is little code, prefer a single file (e.g. `components.ex`).

## Hooks

These are LiveView hooks which register callbacks like `handle_event` and `handle_info`.
Please check `LiveDebugger.App.Web.Helpers.Hooks` module for more information.

Hooks are useful for extracting logic of handling specific messages or events.
Some of them may share assigns so the assigns should be initialized in LiveView and hook should check if they are present in the `socket`.

## Hook components

A hook component (`use LiveDebugger.App.Web, :hook_component`) is a function component that also attaches LiveView hooks (see above) when initialized. The parent LV calls `init(socket)` once in `mount/3` and then renders `<HookComponents.X.render … />` in the template. The component owns its markup, `handle_event/3` and `handle_info/2`, but its state lives on the parent LiveView.

## Nested LiveViews

Some pages (e.g. `Debugger.Web.DebuggerLive`) consist of independent nested LiveViews mounted via [live_render/3](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#live_render/3). It allows each component to subscribe to the topic it needs and removes the need to propagate messages from the parent LiveView to children.

Nested LiveViews should expose a `live_render` component for easy usage (it should handle initial assigns).
