## Browser features

Some features require injecting JS into the debugged application. They are enabled by default, but you can disable them in your config.

```elixir
# config/dev.exs

# Disables all browser features and does not inject LiveDebugger JS
config :live_debugger, :browser_features?, false

# Used when LiveDebugger's assets are exposed on other address (e.g. when run inside Docker)
config :live_debugger, :external_url, "http://localhost:9007"
```

## Content Security Policy

In `router.ex` of your Phoenix app, make sure your locally running Phoenix app can access the LiveDebugger JS files on port 4007. To achieve that you may need to extend your CSP in `:dev` mode:

```elixir
  @csp "{...your CSP} #{if Mix.env() == :dev, do: "http://127.0.0.1:4007"}"

  pipeline :browser do
    # ...
    plug :put_secure_browser_headers, %{"content-security-policy" => @csp}
```

## Disabling LiveDebugger

In case you need LiveDebugger to not run at the start of your application but want to keep the dependency, you can disable it manually in your config:

```elixir
# config/dev.exs

config :live_debugger, :disabled?, true
```

## Default Settings

In LiveDebugger, you can set the default values of settings from the settings panel through your application's config. When starting LiveDebugger, settings will always be set to the values defined in config, but you can still change them temporarily in the settings panel. However, keep in mind that these changes will reset to the config-defined values when you restart the application. These configs should be used when you want to explicitly force a given behavior of LiveDebugger in your project always. If you want settings to persist across restarts (not reset to config values), you need to remove those entries from your application's config file.

```elixir
# config/dev.exs

config :live_debugger,
  dead_view_mode: true,
  garbage_collection: true,
  debug_button: false,
  tracing_enabled_on_start: true,
  highlight_in_browser: true
```

## Other Settings

```elixir
# config/dev.exs

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
