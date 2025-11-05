![LiveDebugger_Chrome_WebStore](https://github.com/user-attachments/assets/cf9aee3b-58ab-4c45-8a43-d73182cb3e02)

<div align="center">

[![Version Badge](https://img.shields.io/github/v/release/software-mansion/live-debugger?color=lawn-green)](https://hexdocs.pm/live_debugger)
[![Hex.pm Downloads](https://img.shields.io/hexpm/dw/live_debugger?style=flat&label=downloads&color=blue)](https://hex.pm/packages/live_debugger)
[![GitHub License](https://img.shields.io/github/license/software-mansion/live-debugger)](https://github.com/software-mansion/live-debugger/blob/main/LICENSE)

</div>

LiveDebugger is a browser-based tool for debugging applications written in [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) - an Elixir library designed for building rich, interactive online experiences with server-rendered HTML.

Designed to enhance your development experience LiveDebugger gives you:

- 🌳 See your LiveComponents tree
- 🔍 View assigns
- 🔗 Trace and filter callback executions
- 🔦 Inspect elements

Check out our comprehensive [Features Overview](https://hexdocs.pm/live_debugger/features.html) to explore all capabilities in detail.

https://github.com/user-attachments/assets/a09d440c-4217-4597-b30e-f8b911a9094a

## Getting started

> [!IMPORTANT]  
> LiveDebugger should not be used on production - make sure that the dependency you've added is `:dev` only

### Mix installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
  defp deps do
    [
      {:live_debugger, "~> 0.4.0", only: :dev}
    ]
  end
```

For full experience we recommend adding below line to your application root layout. It attaches `meta` tag and LiveDebugger scripts in dev environment enabling browser features.

```elixir
  # lib/my_app_web/components/layouts/root.html.heex

  <head>
    <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
  </head>
```

After you start your application, LiveDebugger will be running at a default port `http://localhost:4007`.

### Igniter installation

LiveDebugger has [Igniter](https://github.com/ash-project/igniter) support - an alternative for standard mix installation. It'll automatically add LiveDebugger dependency and modify your `root.html.heex` after you use the below command.

```bash
mix igniter.install live_debugger
```

### DevTools extension

Since version v0.2.0 you can install official LiveDebugger DevTools extension, giving you the ability to interact with its features alongside your application's runtime.

- [Chrome extension](https://chromewebstore.google.com/detail/gmdfnfcigbfkmghbjeelmbkbiglbmbpe)
- [Firefox extension](https://addons.mozilla.org/en-US/firefox/addon/livedebugger-devtools/)

> [!NOTE]  
> Ensure the main LiveDebugger dependency is added to your mix project, as the browser plugin alone is not enough.

## Optional configuration

### Browser features

Some features require injecting JS into the debugged application. They are enabled by default, but you can disable them in your config.

```elixir
# config/dev.exs

# Disables all browser features and does not inject LiveDebugger JS
config :live_debugger, :browser_features?, false

# Disables only debug button
config :live_debugger, :debug_button?, false

# Disables only components highlighting
config :live_debugger, :highlighting?, false

# Used when LiveDebugger's assets are exposed on other address (e.g. when run inside Docker)
config :live_debugger, :external_url, "http://localhost:9007"
```

### Content Security Policy

In `router.ex` of your Phoenix app, make sure your locally running Phoenix app can access the LiveDebugger JS files on port 4007. To achieve that you may need to extend your CSP in `:dev` mode:

```elixir
  @csp "{...your CSP} #{if Mix.env() == :dev, do: "http://127.0.0.1:4007"}"

  pipeline :browser do
    # ...
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
```

### Other

```elixir
# config/dev.exs

# Allows you to disable LiveDebugger manually if needed
config :live_debugger, :disabled?, true

# Time in ms after tracing will be initialized. Useful in case multi-nodes envs
config :live_debugger, :tracing_setup_delay, 0

# Used when working with code reloading and traces are not visible.
# WARNING! This may cause some performance issues.
config :live_debugger, :tracing_update_on_code_reload?, true

# LiveDebugger endpoint config
config :live_debugger,
  ip: {127, 0, 0, 1}, # IP on which LiveDebugger will be hosted
  port: 4007, # Port on which LiveDebugger will be hosted
  secret_key_base: "YOUR_SECRET_KEY_BASE", # Secret key used for LiveDebugger.Endpoint
  signing_salt: "your_signing_salt", # Signing salt used for LiveDebugger.Endpoint
  adapter: Bandit.PhoenixAdapter, # Adapter used in LiveDebugger.Endpoint
  server: true, # Forces LiveDebugger to start even if project is not started with the `mix phx.server`

# Name for LiveDebugger PubSub (it will create new one so don't put already used name)
config :live_debugger, :pubsub_name, LiveDebugger.CustomPubSub
```

## Contributing

For those planning to contribute to this project, you can run a dev version of the debugger with the following commands:

```console
mix setup
iex -S mix
```

It'll run the application declared in the `dev/` directory with the library installed.

LiveReload is working both for `.ex` files and static files, but if some styles don't show up, try using this command

```console
mix assets.build:dev
```

## What's next

To learn about our upcoming plans and developments, please visit our [discussion page](https://github.com/software-mansion/live-debugger/discussions/355).

## Authors

LiveDebugger is created by Software Mansion.

Since 2012 [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger) is a software agency with experience in building web and mobile apps as well as complex multimedia solutions. We are Core React Native Contributors, Elixir ecosystem experts, and live streaming and broadcasting technologies specialists. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects).

Copyright 2025, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=livedebugger-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger)

Licensed under the [Apache License, Version 2.0](LICENSE)
