defmodule LiveDebuggerWeb.LvProcessLive do
  @moduledoc """
  This module is responsible for rendering the main debugger page.
  It can contain multiple nested live views, depending on the current view.
  It also contains the logic for fetching the LiveView process and its state.

  It uses the `LiveDebuggerWeb.Hooks.LinkedView` hook to fetch the LiveView process and its state.
  """

  use LiveDebuggerWeb, :live_view
  use LiveDebuggerWeb.Hooks.LinkedView

  require Logger

  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebuggerWeb.Components.Navbar
  alias Phoenix.LiveView.JS

  alias LiveDebuggerWeb.Live.Nested.StateLive
  alias LiveDebuggerWeb.Live.Nested.NodeInspectorSidebarLive
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Components.NavigationMenu
  alias LiveDebuggerWeb.Live.Traces.NodeTracesLive
  alias LiveDebuggerWeb.Live.Traces.ProcessTracesLive

  @impl true
  def handle_params(params, _url, socket) do
    self()
    |> PubSubUtils.params_changed_topic()
    |> PubSubUtils.broadcast({:params_changed, params})

    {:noreply, assign(socket, :params, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="lv-process-live" class="w-screen h-screen grid grid-rows-[auto_1fr]">
      <.async_result :let={lv_process} assign={@lv_process}>
        <:loading>
          <div class="flex h-screen items-center justify-center">
            <.spinner size="xl" />
          </div>
        </:loading>

        <Navbar.navbar class="grid grid-cols-[auto_auto_1fr_auto] pl-2 lg:pr-4">
          <Navbar.return_link
            return_link={get_return_link(lv_process, @in_iframe?)}
            class="hidden sm:block"
          />
          <NavigationMenu.dropdown
            return_link={get_return_link(lv_process, @in_iframe?)}
            current_url={@url}
            class="sm:hidden"
          />
          <Navbar.live_debugger_logo_icon />
          <Navbar.connected id="navbar-connected" lv_process={lv_process} />
          <div class="flex items-center gap-2">
            <Navbar.settings_button return_to={@url} />
            <span class="h-5 border-r border-default-border lg:hidden"></span>
            <.nav_icon
              phx-click={if @lv_process.ok?, do: get_open_sidebar_js(@live_action)}
              class="flex lg:hidden"
              icon="icon-panel-right"
            />
          </div>
        </Navbar.navbar>
        <div class="flex overflow-hidden w-full">
          <NavigationMenu.sidebar class="hidden sm:flex" current_url={@url} />
          <.node_inspector
            :if={@live_action == :node_inspector}
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            params={@params}
          />
          <.global_traces
            :if={@live_action == :global_traces}
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            params={@params}
          />
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("find-successor", _, socket) do
    send(self(), :find_successor)

    {:noreply, socket}
  end

  attr(:socket, :map, required: true)
  attr(:lv_process, :map, required: true)
  attr(:url, :string, required: true)
  attr(:params, :map, required: true)

  defp node_inspector(assigns) do
    ~H"""
    <div class="flex grow flex-col gap-4 p-8 overflow-y-auto max-w-screen-2xl mx-auto scrollbar-main">
      <StateLive.live_render
        id="node-state-lv"
        class="flex"
        socket={@socket}
        lv_process={@lv_process}
        params={@params}
      />
      <NodeTracesLive.live_render
        id="traces-list"
        class="flex"
        socket={@socket}
        lv_process={@lv_process}
        params={@params}
      />
    </div>
    <NodeInspectorSidebarLive.live_render
      id="sidebar"
      class="h-full"
      socket={@socket}
      lv_process={@lv_process}
      url={@url}
      params={@params}
    />
    """
  end

  defp global_traces(assigns) do
    ~H"""
    <ProcessTracesLive.live_render
      id="global-traces"
      class="flex overflow-hidden w-full"
      socket={@socket}
      lv_process={@lv_process}
      params={@params}
    />
    """
  end

  defp get_return_link(lv_process, in_iframe?) do
    cond do
      not in_iframe? ->
        RoutesHelper.live_views_dashboard()

      in_iframe? ->
        RoutesHelper.window_dashboard(lv_process.transport_pid)
    end
  end

  defp get_open_sidebar_js(live_action) do
    case live_action do
      :node_inspector -> JS.push("open-sidebar", target: "#sidebar")
      :global_traces -> JS.push("open-sidebar", target: "#global-traces")
    end
  end
end
