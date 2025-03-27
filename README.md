# LiveDebugger

LiveDebugger is a browser-based tool for debugging applications written in [Phoenix LiveView](https://github.com/phoenixframework/phoenix_live_view) - an Elixir library designed for building rich, interactive online experiences with server-rendered HTML.

Designed to enhance your development experience LiveDebugger gives you:

- :deciduous_tree: A detailed view of your LiveComponents tree
- :mag: The ability to inspect assigns for LiveViews and LiveComponents
- :link: Tracing of their callback executions

https://github.com/user-attachments/assets/37f1219c-93cc-4d06-96f7-9b2140a1c971

## Installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
  defp deps do
    [
      {:live_debugger, "~> 0.1.3", only: :dev}
    ]
  end
```

After you start your application LiveDebugger will be running at a default port `http://localhost:4007`.

## Browser features

List of browser features:

- Debug button
- Components highlighting (coming soon!)

Some features require injecting JS into the debugged application. To achieve that you need to turn them on in the config and add LiveDebugger scripts to your application root layout.

```elixir
# config/dev.exs

config :live_debugger, browser_features?: true
```

```elixir
# lib/my_app_web/components/layouts/root.html.heex

<head>
  <%= if Application.get_env(:live_debugger, :browser_features?) do %>
    <script id="live-debugger-scripts" src={Application.get_env(:live_debugger, :assets_url)}>
    </script>
  <% end %>
</head>
```

### Content Security Policy

In `router.ex` of your Phoenix app, make sure your locally running Phoenix app can access the LiveDebugger JS files on port 4007. To achieve that you may need to extend your CSP in `:dev` mode:

```elixir
  @csp "{...your CSP} #{if Mix.env() == :dev, do: "http://127.0.0.1:4007"}"

  pipeline :browser do
    # ...
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
```

## Optional configuration

```elixir
# config/dev.exs

config :live_debugger,
  ip: {127, 0, 0, 1}, # IP on which LiveDebugger will be hosted
  port: 4007, # Port on which LiveDebugger will be hosted
  secret_key_base: <SECRET_KEY_BASE>, # Secret key used for LiveDebugger.Endpoint
  signing_salt: "your_signing_salt", # Signing salt used for LiveDebugger.Endpoint
  adapter: Bandit.PhoenixAdapter # Adapter used in LiveDebugger.Endpoint
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
