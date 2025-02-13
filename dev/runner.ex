defmodule LiveDebuggerDev.Runner do
  def run() do
    # Configures the endpoint
    Application.put_env(:live_debugger_dev_app, LiveDebuggerDev.Endpoint,
      url: [host: "localhost"],
      secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
      live_view: [signing_salt: "hMegieSe"],
      http: [port: System.get_env("PORT") || 4004],
      debug_errors: true,
      check_origin: false,
      pubsub_server: LiveDebuggerDev.PubSub,
      adapter: Bandit.PhoenixAdapter,
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:default, ~w(--watch)]},
        tailwind: {Tailwind, :install_and_run, [:live_debugger, ~w(--watch)]}
      ],
      live_reload: [
        patterns: [
          ~r"priv/static/.*(js|css)$",
          ~r"lib/live_debugger/live_views/.*(ex)$",
          ~r"lib/live_debugger/live_components/.*(ex)$",
          ~r"lib/live_debugger/components/.*(ex)$",
          ~r"lib/live_debugger/components.ex",
          ~r"lib/live_debugger/layout.ex",
          ~r"dev/live_views/.*(ex)$",
          ~r"dev/live_components/.*(ex)$",
          ~r"dev/layout.ex"
        ]
      ]
    )

    Application.put_env(:phoenix, :serve_endpoints, true)

    Task.async(fn ->
      children = [
        {Phoenix.PubSub, name: LiveDebuggerDev.PubSub},
        LiveDebuggerDev.Endpoint
      ]

      {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)

      # For some reason `Application.put_env` doesn't work and LiveDebugger starts without config
      Application.stop(:live_debugger)
      Application.start(:live_debugger)

      Process.sleep(:infinity)
    end)
  end
end
