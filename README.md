# LiveDebugger

## Local installation

Clone repository with:

```bash
git clone https://github.com/software-mansion-labs/live_debugger.git
```

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

## Contributing

For those planning to contribute to this project, you can run a dev version of the debugger with the following commands:

```bash
mix setup
mix dev
```
