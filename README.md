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

After that you can add LiveDebugger to your router (do not put it into any `scope`):

```elixir
import LiveDebugger.Router

scope "/" do
  pipe_through :browser

  live "/", CounterLive
end

live_debugger "/live_debug"
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
iex -S mix
```

It'll run application declared in `dev/` directory with library debugger installed.

LiveReload is working both for `.ex` files and static files, but if some styles won't show up, try using this command

```bash
mix assets.build
```

### Heroicons

Heroicons are not used as dependency but copied from [Heroicons](https://github.com/tailwindlabs/heroicons) .
To copy them you can use `copy_heroicons.sh` script which requires you to have heroicons cloned in folder next to `live_debugger` folder.
