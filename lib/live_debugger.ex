defmodule LiveDebugger do
  @moduledoc """
  Debugger for LiveView applications.
  """
  use Application

  require Logger

  alias LiveDebugger.API.SettingsStorage

  @app_name :live_debugger

  @default_ip {127, 0, 0, 1}
  @default_port 4007
  @default_secret_key_base "DEFAULT_SECRET_KEY_BASE_1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZabcd"
  @default_signing_salt "live_debugger_signing_salt"
  @default_drainer [shutdown: 1000]

  @js_path "assets/live_debugger/client.js"
  @css_path "assets/live_debugger/client.css"
  @phoenix_path "assets/phoenix/phoenix.js"

  def start(_type, _args) do
    disabled? = Application.get_env(@app_name, :disabled?, false)
    children = if disabled?, do: [], else: get_children()
    Supervisor.start_link(children, strategy: :one_for_one, name: LiveDebugger.Supervisor)
  end

  def update_live_debugger_tags() do
    config = Application.get_all_env(@app_name)
    endpoint_config = Application.get_env(@app_name, LiveDebugger.App.Web.Endpoint, [])

    resolved_port =
      get_in(endpoint_config, [:http, :port]) || Keyword.get(config, :port, @default_port)

    put_live_debugger_tags(config, resolved_port)
  end

  defp get_children() do
    if LiveDebugger.Env.unit_test?() do
      []
    else
      LiveDebugger.API.SettingsStorage.init()
      LiveDebugger.API.TracesStorage.init()
      LiveDebugger.API.StatesStorage.init()

      config = Application.get_all_env(@app_name)
      resolved_port = put_endpoint_config(config)
      put_live_debugger_tags(config, resolved_port)

      []
      |> LiveDebugger.App.append_app_children()
      |> LiveDebugger.Bus.append_bus_tree()
      |> LiveDebugger.Services.append_services_children()
    end
  end

  defp default_adapter() do
    case Code.ensure_loaded(Bandit.PhoenixAdapter) do
      {:module, _} -> Bandit.PhoenixAdapter
      {:error, _} -> Phoenix.Endpoint.Cowboy2Adapter
    end
  end

  defp put_endpoint_config(config) do
    ip = Keyword.get(config, :ip, @default_ip)
    port = Keyword.get(config, :port, @default_port)
    auto_port? = Keyword.get(config, :auto_port, false)

    resolved_port =
      if auto_port? and is_integer(port) and port > 0 do
        find_available_port(ip, port)
      else
        port
      end

    endpoint_config =
      [
        http: [
          ip: ip,
          port: resolved_port
        ],
        secret_key_base: Keyword.get(config, :secret_key_base, @default_secret_key_base),
        live_view: [signing_salt: Keyword.get(config, :signing_salt, @default_signing_salt)],
        adapter: Keyword.get(config, :adapter, default_adapter()),
        live_reload: Keyword.get(config, :live_reload, []),
        drainer: Keyword.get(config, :drainer, @default_drainer)
      ]

    endpoint_server = Keyword.get(config, :server)

    endpoint_config =
      if is_nil(endpoint_server) do
        endpoint_config
      else
        Keyword.put(endpoint_config, :server, endpoint_server)
      end

    Application.put_env(@app_name, LiveDebugger.App.Web.Endpoint, endpoint_config)

    resolved_port
  end

  defp find_available_port(_ip, port) when port > 65535, do: port

  defp find_available_port(ip, port) do
    case :gen_tcp.listen(port, [:inet, {:ip, ip}]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        port

      {:error, :eaddrinuse} ->
        Logger.warning("LiveDebugger: port #{port} is already in use, trying #{port + 1}")
        find_available_port(ip, port + 1)

      {:error, _} ->
        port
    end
  end

  defp put_live_debugger_tags(config, resolved_port) do
    default_url =
      case Keyword.get(config, :ip, @default_ip) do
        {:local, _path} -> nil
        ip_tuple -> "http://#{ip_tuple |> :inet.ntoa() |> List.to_string()}:#{resolved_port}"
      end

    live_debugger_url = Keyword.get(config, :external_url, default_url)

    if is_nil(live_debugger_url) do
      Logger.warning(
        "LiveDebugger is configured with a Unix socket but no :external_url is set. " <>
          "Browser features (debug button, elements inspection) will be disabled. " <>
          "Set config :live_debugger, external_url: \"http://your_external_url\" to enable them."
      )

      Application.put_env(@app_name, :live_debugger_tags, [])
    else
      browser_features? = Keyword.get(config, :browser_features?, true)
      version = Application.spec(@app_name)[:vsn] |> to_string()

      live_debugger_js_url = "#{live_debugger_url}/#{@js_path}"
      live_debugger_css_url = "#{live_debugger_url}/#{@css_path}"
      live_debugger_phoenix_url = "#{live_debugger_url}/#{@phoenix_path}"

      assigns = %{
        url: live_debugger_url,
        js_url: live_debugger_js_url,
        css_url: live_debugger_css_url,
        phoenix_url: live_debugger_phoenix_url,
        browser_features?: browser_features?,
        version: version,
        debug_button?: SettingsStorage.get(:debug_button)
      }

      tags = LiveDebugger.Client.ConfigComponent.live_debugger_tags(assigns)
      Application.put_env(@app_name, :live_debugger_tags, tags)
    end
  end
end
