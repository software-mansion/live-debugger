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

Then you need to configure `LiveDebugger.Endpoint` similarly to `YourApplication.Endpoint`

```elixir
# config/dev.exs

config :live_debugger, LiveDebugger.Endpoint,
  http: [port: 4007], # Add port on which you want debugger to run
  secret_key_base: <SECRET_KEY_BASE>, # Generate secret using `mix phx.gen.secret`
  live_view: [signing_salt: <SIGNING_SALT>], # Random 12 letter salt
  adapter: Bandit.PhoenixAdapter # Change to your adapter if other is used (see your Endpoint config)
```

For easy navigation add the debug button to your live layout

```Elixir
# lib/my_app_web/components/app.html.heex

<main>
  <%= if Mix.env() == :dev do %>
    <LiveDebugger.Helpers.debug_button socket_id={@socket.id} />
  <% end %>
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
