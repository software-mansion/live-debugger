defmodule LiveDebuggerDev.Runner do
  def run() do
    # Configures the endpoint

    config =
      if Mix.env() == :test do
        common_config() ++ test_only_config()
      else
        common_config() ++ dev_only_config()
      end

    Application.put_env(:live_debugger_dev_app, LiveDebuggerDev.Endpoint, config)

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

  defp common_config() do
    [
      url: [host: "localhost"],
      secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
      live_view: [signing_salt: "hMegieSe"],
      debug_errors: true,
      check_origin: false,
      pubsub_server: LiveDebuggerDev.PubSub,
      adapter: Bandit.PhoenixAdapter
    ]
  end

  defp dev_only_config() do
    [
      http: [port: System.get_env("PORT") || 4004],
      watchers: [
        esbuild: {Esbuild, :install_and_run, [:dev_build, ~w(--watch)]},
        tailwind: {Tailwind, :install_and_run, [:dev_build, ~w(--watch)]}
      ],
      live_reload: [
        patterns: [
          ~r"priv/static/.*(js|css|svg)$",
          ~r"priv/static/dev/.*(js|css|svg)$",
          ~r"dev/live_views/.*(ex)$",
          ~r"dev/live_components/.*(ex)$",
          ~r"dev/layout.ex"
        ]
      ]
    ]
  end

  defp test_only_config() do
    [
      http: [port: 4005],
      server: true
    ]
  end
end
