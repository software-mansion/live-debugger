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
  @phoenix_path "assets/phoenix/phoenix.js"

  def start(_type, _args) do
    disabled? = Application.get_env(@app_name, :disabled?, false)
    children = if disabled?, do: [], else: get_children()
    Supervisor.start_link(children, strategy: :one_for_one, name: LiveDebugger.Supervisor)
  end

  defp get_children() do
    config = Application.get_all_env(@app_name)

    put_endpoint_config(config)
    put_live_debugger_tags(config)

    if Application.get_env(@app_name, :refactor, false) do
      LiveDebuggerRefactor.API.SettingsStorage.init()
      LiveDebuggerRefactor.API.TracesStorage.init()
      LiveDebuggerRefactor.API.StatesStorage.init()

      get_refactor_children()
    else
      get_legacy_children(config)
    end
  end

  defp get_refactor_children() do
    if LiveDebuggerRefactor.Env.unit_test?() do
      []
    else
      []
      |> LiveDebuggerRefactor.App.append_app_children()
      |> LiveDebuggerRefactor.Bus.append_bus_tree()
      |> LiveDebuggerRefactor.Services.append_services_children()
    end
  end

  defp get_legacy_children(config) do
    pubsub_name = Keyword.get(config, :pubsub_name, LiveDebugger.PubSub)

    children = [
      {Phoenix.PubSub, name: pubsub_name},
      {LiveDebuggerWeb.Endpoint,
       [
         check_origin: false,
         pubsub_server: pubsub_name
       ]}
    ]

    if LiveDebugger.Env.unit_test?() do
      children
    else
      children ++
        [
          {LiveDebugger.GenServers.SettingsServer, []},
          {LiveDebugger.GenServers.EtsTableServer, []},
          {LiveDebugger.GenServers.StateServer, []},
          {LiveDebugger.GenServers.CallbackTracingServer, []}
        ]
    end
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

    endpoint_server = Keyword.get(config, :server)

    endpoint_config =
      if is_nil(endpoint_server) do
        endpoint_config
      else
        Keyword.put(endpoint_config, :server, endpoint_server)
      end

    Application.put_env(@app_name, LiveDebuggerWeb.Endpoint, endpoint_config)
    Application.put_env(@app_name, LiveDebuggerRefactor.App.Web.Endpoint, endpoint_config)
  end

  defp put_live_debugger_tags(config) do
    ip_string = config |> Keyword.get(:ip, @default_ip) |> :inet.ntoa() |> List.to_string()
    port = Keyword.get(config, :port, @default_port)

    browser_features? = Keyword.get(config, :browser_features?, true)
    debug_button? = Keyword.get(config, :debug_button?, true)
    highlighting? = Keyword.get(config, :highlighting?, true)
    refactor? = Keyword.get(config, :refactor?, false)
    version = Application.spec(@app_name)[:vsn] |> to_string()
    dead_view_mode = Keyword.get(config, :dead_view_mode, true)

    devtools_allow_redirects = Keyword.get(config, :devtools_allow_redirects, not dead_view_mode)
    live_debugger_url = Keyword.get(config, :external_url, "http://#{ip_string}:#{port}")
    live_debugger_assets_url = "#{live_debugger_url}/#{@assets_path}"
    live_debugger_phoenix_url = "#{live_debugger_url}/#{@phoenix_path}"

    assigns = %{
      url: live_debugger_url,
      assets_url: live_debugger_assets_url,
      phoenix_url: live_debugger_phoenix_url,
      browser_features?: browser_features?,
      debug_button?: debug_button?,
      highlighting?: highlighting?,
      refactor?: refactor?,
      version: version,
      devtools_allow_redirects: devtools_allow_redirects
    }

    tags = LiveDebuggerWeb.Components.Config.live_debugger_tags(assigns)
    Application.put_env(@app_name, :live_debugger_tags, tags)
  end
end
