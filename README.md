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
      LiveDebugger.Supervisor,
      LvdTestWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

```

Then you need to configure it inside your config file:

```elixir
# config/dev.exs

config :live_debugger, LiveDebugger.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: <PORT>],
  check_origin: false,
  secret_key_base: <SECRET KEY BASE>,
  adapter: Bandit.PhoenixAdapter,
  pubsub_server: LiveDebugger.PubSub,
  live_view: [signing_salt: <SIGNING SALT>]

```

For easy navigation add the debug button to your live layout:

```Elixir
# lib/my_app_web/components/app.html.heex

<main>
  <LiveDebugger.debug_button socket_id={@socket.id} />
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
