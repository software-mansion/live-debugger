defmodule LiveDebugger do
  @moduledoc """
  Debugger for LiveView applications.
  """

  use Application

  @app_name :live_debugger

  @default_ip {127, 0, 0, 1}
  @default_port 4007
  @default_secret_key_base "DEFAULT_SECRET_KEY_BASE_1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcd"
  @default_signing_salt "live_debugger_signing_salt"

  @assets_path "assets/live_debugger/client.js"

  def start(_type, _args) do
    config = Application.get_all_env(@app_name)

    default_adapter = default_adapter()
    ip = Keyword.get(config, :ip, @default_ip)
    ip_string = ip |> :inet.ntoa() |> List.to_string()
    port = Keyword.get(config, :port, @default_port)

    endpoint_config =
      [
        http: [ip: ip, port: port],
        secret_key_base: Keyword.get(config, :secret_key_base, @default_secret_key_base),
        live_view: [signing_salt: Keyword.get(config, :signing_salt, @default_signing_salt)],
        adapter: Keyword.get(config, :adapter, default_adapter),
        live_reload: Keyword.get(config, :live_reload, [])
      ]

    Application.put_env(@app_name, LiveDebugger.Endpoint, endpoint_config)
    Application.put_env(@app_name, :assets_url, "http://#{ip_string}:#{port}/#{@assets_path}")

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
