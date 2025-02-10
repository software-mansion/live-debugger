defmodule LiveDebugger do
  @moduledoc """
  Debugger for LiveView applications.
  """

  use Application

  @default_port 4007
  @default_secret_key_base "DEFAULT_SECRET_KEY_BASE_1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcd"
  @default_signing_salt "live_debugger_signing_salt"

  def start(_type, _args) do
    config = Application.get_all_env(:live_debugger)
    default_adapter = default_adapter()

    endpoint_config =
      [
        http: [port: Keyword.get(config, :port, @default_port)],
        secret_key_base: Keyword.get(config, :secret_key_base, @default_secret_key_base),
        live_view: [signing_salt: Keyword.get(config, :signing_salt, @default_signing_salt)],
        adapter: Keyword.get(config, :adapter, default_adapter)
      ]

    Application.put_env(:live_debugger, LiveDebugger.Endpoint, endpoint_config)

    unless Keyword.has_key?(config, :port) do
      Application.put_env(:live_debugger, :port, @default_port)
    end

    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         check_origin: false,
         pubsub_server: LiveDebugger.PubSub
       ]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: LiveDebugger.Supervisor)
  end

  defp default_adapter() do
    case Code.ensure_loaded(Bandit.PhoenixAdapter) do
      {:module, _} -> Bandit.PhoenixAdapter
      {:error, _} -> Phoenix.Endpoint.Cowboy2Adapter
    end
  end
end
