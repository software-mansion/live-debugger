# Configures the endpoint
Application.put_env(:live_debugger_dev_app, LiveDebuggerDev.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
  live_view: [signing_salt: "hMegieSe"],
  http: [port: System.get_env("PORT") || 4004],
  debug_errors: true,
  check_origin: false,
  pubsub_server: LiveDebugger.PubSub,
  adapter: Bandit.PhoenixAdapter
  # watchers: [
  #   esbuild: {Esbuild, :install_and_run, [:default, ~w(--watch)]},
  #   sass: {DartSass, :install_and_run, [:default, ~w(--watch)]}
  # ],
  # live_reload: [
  #   patterns: [
  #     ~r"dist/.*(js|css|png|jpeg|jpg|gif|svg)$",
  #     ~r"lib/phoenix/live_dashboard/(live|views)/.*(ex)$",
  #     ~r"lib/phoenix/live_dashboard/templates/.*(ex)$"
  #   ]
  # ]
)

Application.put_env(:phoenix, :serve_endpoints, true)

Task.async(fn ->
  children = [
    {Phoenix.PubSub, name: LiveDebuggerDev.PubSub},
    LiveDebuggerDev.Endpoint
  ]

  {:ok, _} = Supervisor.start_link(children, strategy: :one_for_one)
  Process.sleep(:infinity)
end)
|> Task.await(:infinity)
