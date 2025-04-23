![LiveDebugger_Chrome_WebStore](https://github.com/user-attachments/assets/cf9aee3b-58ab-4c45-8a43-d73182cb3e02)


LiveDebugger is a browser-based tool for debugging applications written in [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) - an Elixir library designed for building rich, interactive online experiences with server-rendered HTML.

Designed to enhance your development experience LiveDebugger gives you:

- :deciduous_tree: A detailed view of your LiveComponents tree
- :mag: The ability to inspect assigns for LiveViews and LiveComponents
- :link: Tracing of their callback executions

https://github.com/user-attachments/assets/37f1219c-93cc-4d06-96f7-9b2140a1c971

## Getting started
> [!IMPORTANT]  
> LiveDebugger should not be used on production - make sure that the dependency you've added is `:dev` only

### Mix installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
  defp deps do
    [
      {:live_debugger, "~> 0.1.6", only: :dev}
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

### Browser features
Some features require injecting JS into the debugged application. They are enabled by default, but you can disable them in your config.

```elixir
# config/dev.exs

# Disables all browser features and does not inject LiveDebugger JS
config :live_debugger, browser_features?: false

# Disables only debug button
config :live_debugger, debug_button?: false
```

### Content Security Policy

In `router.ex` of your Phoenix app, make sure your locally running Phoenix app can access the LiveDebugger JS files on port 4007. To achieve that you may need to extend your CSP in `:dev` mode:

```elixir
  @csp "{...your CSP} #{if Mix.env() == :dev, do: "http://127.0.0.1:4007"}"

  pipeline :browser do
    # ...
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
```

### Optional configuration

```elixir
# config/dev.exs

config :live_debugger,
  ip: {127, 0, 0, 1}, # IP on which LiveDebugger will be hosted
  port: 4007, # Port on which LiveDebugger will be hosted
  secret_key_base: <SECRET_KEY_BASE>, # Secret key used for LiveDebugger.Endpoint
  signing_salt: "your_signing_salt", # Signing salt used for LiveDebugger.Endpoint
  adapter: Bandit.PhoenixAdapter # Adapter used in LiveDebugger.Endpoint
  tracing_setup_delay: 0 # Time in ms after tracing will be initialized. Useful in case multi-nodes envs
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

## Authors

LiveDebugger is created by Software Mansion.

Since 2012 [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger) is a software agency with experience in building web and mobile apps as well as complex multimedia solutions. We are Core React Native Contributors, Elixir ecosystem experts, and live streaming and broadcasting technologies specialists. We can help you build your next dream product – [Hire us](https://swmansion.com/contact/projects).

Copyright 2025, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=livedebugger-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=livedebugger)

Licensed under the [Apache License, Version 2.0](LICENSE)
