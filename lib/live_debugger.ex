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

    put_endpoint_config(config)
    put_live_debugger_tags(config)

    children = [
      {Phoenix.PubSub, name: LiveDebugger.PubSub},
      {LiveDebugger.Endpoint,
       [
         check_origin: false,
         pubsub_server: LiveDebugger.PubSub
       ]}
    ]

    children =
      if LiveDebugger.Env.unit_test?() do
        children
      else
        children ++
          [
            {LiveDebugger.GenServers.CallbackTracingServer, []}
          ]
      end

    Supervisor.start_link(children, strategy: :one_for_one, name: LiveDebugger.Supervisor)
  end

  defp default_adapter() do
    case Code.ensure_loaded(Bandit.PhoenixAdapter) do
      {:module, _} -> Bandit.PhoenixAdapter
      {:error, _} -> Phoenix.Endpoint.Cowboy2Adapter
    end
  end

  defp put_endpoint_config(config) do
    endpoint_config =
      [
        http: [
          ip: Keyword.get(config, :ip, @default_ip),
          port: Keyword.get(config, :port, @default_port)
        ],
        secret_key_base: Keyword.get(config, :secret_key_base, @default_secret_key_base),
        live_view: [signing_salt: Keyword.get(config, :signing_salt, @default_signing_salt)],
        adapter: Keyword.get(config, :adapter, default_adapter()),
        live_reload: Keyword.get(config, :live_reload, [])
      ]

    Application.put_env(@app_name, LiveDebugger.Endpoint, endpoint_config)
  end

  defp put_live_debugger_tags(config) do
    ip_string = config |> Keyword.get(:ip, @default_ip) |> :inet.ntoa() |> List.to_string()
    port = Keyword.get(config, :port, @default_port)

    browser_features? = Keyword.get(config, :browser_features?, true)
    debug_button? = Keyword.get(config, :debug_button?, true)

    live_debugger_url = "http://#{ip_string}:#{port}"
    live_debugger_assets_url = "http://#{ip_string}:#{port}/#{@assets_path}"

    assigns = %{
      url: live_debugger_url,
      assets_url: live_debugger_assets_url,
      browser_features?: browser_features?,
      debug_button?: debug_button?
    }

    tags = LiveDebugger.Components.Config.live_debugger_tags(assigns)
    Application.put_env(@app_name, :live_debugger_tags, tags)
  end
end
