# LiveDebugger

## Local installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_debugger, path: "../path/to/library"}
  ]
end
```

After that you can add the "Hello World" LiveView to your router:

```elixir
  live_session :default do
    live "/hello", LiveDebugger.Web.HelloLive
  end
```
