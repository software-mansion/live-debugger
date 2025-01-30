# LiveDebugger

## Installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_debugger, git: "git@github.com:software-mansion-labs/live-debugger.git", tag: "v0.0.2", only: :dev}
  ]
end
```

After that you need to add `LiveDebugger.Supervisor` under your supervision tree:

```elixir
# lib/my_app/application.ex

  @impl true
  def start(_type, _args) do
    children = [
      {Phoenix.PubSub, name: MyApp.PubSub},
      MyApp.Endpoint
    ]

    children =
      if Mix.env() == :dev,
        do: [LiveDebugger.Supervisor | children],
        else: children

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

```

Then you need to configure `LiveDebugger.Endpoint`. To generate secret keys use [phx.gen.secret](https://hexdocs.pm/phoenix/Mix.Tasks.Phx.Gen.Secret.html).

```elixir
# config/dev.exs

config :live_debugger, LiveDebugger.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4001], # Add port on which you want debugger to run
  secret_key_base: <SECRET_KEY_BASE>, # Generate 64 letter key
  live_view: [signing_salt: <SIGNING_SALT>], # Generate 12 letter key
  adapter: <ADAPTER_MODULE> # Use your adapter (e.g `Bandit.PhoenixAdapter`)
```

For easy navigation add the debug button to your live layout

```Elixir
# lib/my_app_web/components/app.html.heex

<main>
  <LiveDebugger.debug_button
    :if={Mix.env() == :dev}
    redirect_url="/live_debug"
    socket_id={@socket.id}
  />
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
