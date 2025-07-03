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
