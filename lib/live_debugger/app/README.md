# App

LiveView UI application. It follows some predefined conventions.

## File / folder structure

Each page is structured to contain elements which are inside nested in folder (e.g. nested live views are subfolder of live view in which they are used).
If the components are shared between pages/bigger ui parts put them on the nearest connection branch.

Each **feature** (page or bigger ui element) (`debugger/`, `discovery/`, `settings/`) follows the same internal layout:

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

Not all folders are necessary and if there is little code then it is better to use a single file (e.g. `components.ex`)

## Hooks

These are LiveView hooks which register callbacks like `handle_event` and `handle_info`.
Please check `LiveDebugger.App.Web.Helpers.Hooks` module for more information.

Hooks are useful for extracting logic of handling specific messages or events.
Some of them may share assigns so the assigns should be initialized in LiveView and hook should check if they are present in the `socket`.

## Hook components

A hook component (`use LiveDebugger.App.Web, :hook_component`) is a function component that also attaches LiveView hooks (see above) when initialized. The parent LV calls `init(socket)` once in `mount/3` and then renders `<HookComponents.X.render … />` in the template. The component owns its markup, `handle_event/3` and `handle_info/2`, but its state lives on the parent LiveView.

## Nested LiveViews

The debugger page (`Debugger.Web.DebuggerLive`) is a shell which consist of independent nested LiveViews mounted via [live_render/3](https://hexdocs.pm/phoenix_live_view/Phoenix.Component.html#live_render/3). It allows each component to subscribe on the topic it needs and also removes need for propagating messages to children from parent LiveView.

Nested LiveViews should expose a `live_render` component for easy usage (it should handle initial assigns).
