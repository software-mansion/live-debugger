# LiveDebugger

LiveDebugger is a browser-based tool for debugging LiveView applications.
It provides insights into your LiveViews, their LiveComponents, events, state transitions, and more.
![output](https://github.com/user-attachments/assets/ba35716e-162b-4edd-a56e-de83294510f1)

## Installation

Add `live_debugger` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:live_debugger, git: "git@github.com:software-mansion-labs/live-debugger.git", tag: "v0.0.3", only: :dev}
  ]
end
```

Then you need to configure `LiveDebugger.Endpoint` similarly to `YourApplication.Endpoint`

```elixir
# config/dev.exs

config :live_debugger, LiveDebugger.Endpoint,
  http: [port: 4007], # Add port on which you want debugger to run
  secret_key_base: <SECRET_KEY_BASE>, # Generate secret using `mix phx.gen.secret`
  live_view: [signing_salt: "your_signing_salt"],
  adapter: Bandit.PhoenixAdapter # Change to your adapter if other is used
```

Live debugger will be running at separate port which you've provided e.g. http://localhost:4007 .

## Adding button

For easy navigation add the optional debug button to your live layout. Make sure that it is not used in production! (`:live_debugger` is `:dev` only - this code won't compile in `:prod` environment)

```elixir
# lib/my_app_web/components/app.html.heex

<main>
  ...
  <%= if Application.ensure_started(:live_debugger) == :ok do %>
    <LiveDebugger.Helpers.debug_button socket_id={@socket.id} />
  <% end %>

  {@inner_content}
</main>
```

This code will produce a warning when compiled in `MIX_ENV=prod`

## Contributing

For those planning to contribute to this project, you can run a dev version of the debugger with the following commands:

```console
mix setup
iex -S mix
```

It'll run application declared in `dev/` directory with library debugger installed.

LiveReload is working both for `.ex` files and static files, but if some styles won't show up, try using this command

```console
mix assets.build
```

### Heroicons

Heroicons are not used as dependency but copied from [Heroicons](https://github.com/tailwindlabs/heroicons) .
To copy them you can use `copy_heroicons.sh` script which requires you to have heroicons cloned in folder next to `live_debugger` folder.

