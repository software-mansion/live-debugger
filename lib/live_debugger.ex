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

  @js_path "assets/live_debugger/client.js"
  @css_path "assets/live_debugger/client.css"
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

    if LiveDebugger.Env.unit_test?() do
      []
    else
      LiveDebugger.API.SettingsStorage.init()
      LiveDebugger.API.TracesStorage.init()
      LiveDebugger.API.StatesStorage.init()

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

    Application.put_env(@app_name, LiveDebugger.App.Web.Endpoint, endpoint_config)
  end

  defp put_live_debugger_tags(config) do
    ip_string = config |> Keyword.get(:ip, @default_ip) |> :inet.ntoa() |> List.to_string()
    port = Keyword.get(config, :port, @default_port)

    browser_features? = Keyword.get(config, :browser_features?, true)
    debug_button? = Keyword.get(config, :debug_button?, true)
    highlighting? = Keyword.get(config, :highlighting?, true)
    version = Application.spec(@app_name)[:vsn] |> to_string()

    live_debugger_url = Keyword.get(config, :external_url, "http://#{ip_string}:#{port}")
    live_debugger_js_url = "#{live_debugger_url}/#{@js_path}"
    live_debugger_css_url = "#{live_debugger_url}/#{@css_path}"
    live_debugger_phoenix_url = "#{live_debugger_url}/#{@phoenix_path}"

    assigns = %{
      url: live_debugger_url,
      js_url: live_debugger_js_url,
      css_url: live_debugger_css_url,
      phoenix_url: live_debugger_phoenix_url,
      browser_features?: browser_features?,
      debug_button?: debug_button?,
      highlighting?: highlighting?,
      version: version
    }

    tags = LiveDebugger.Client.ConfigComponent.live_debugger_tags(assigns)
    Application.put_env(@app_name, :live_debugger_tags, tags)
  end
end
