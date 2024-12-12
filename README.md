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

After that you can add LiveDebugger to your router:

```elixir
import LiveDebugger.Router

scope "/" do
  pipe_through :browser

  live "/", CounterLive
  live_debugger "/live_debug"
end
```

And add the debug button to your app layout:

```Elixir
<main>
  <LiveDebugger.debug_button redirect_url="/live_debug" socket_id={@socket.id} />
  {@inner_content}
</main>
```

## Contributing

For those planning to contribute to this project, you can run a dev version of the debugger with the following commands:

```bash
mix setup
mix dev
```

It'll run application declared in `dev/` directory with library debugger installed.

LiveReload is working both for `.ex` files and static files, but if some styles won't show up, try using this command

```bash
mix assets.build
```
