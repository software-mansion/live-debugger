defmodule LiveDebuggerWeb.LvProcessLive do
  @moduledoc false

  use LiveDebuggerWeb, :live_view
  use LiveDebuggerWeb.Hooks.LinkedView

  require Logger

  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebuggerWeb.Components.Navbar
  alias Phoenix.LiveView.JS

  alias LiveDebugger.Structs.TreeNode

  alias LiveDebuggerWeb.StateLive
  alias LiveDebuggerWeb.TracesLive
  alias LiveDebuggerWeb.SidebarLive
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Components.NavigationMenu

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> assign_node_id(params)
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="channel-dashboard" class="w-screen h-screen grid grid-rows-[auto_1fr]">
      <Navbar.navbar class="grid grid-cols-[auto_auto_1fr_auto] pl-2 lg:pr-4">
        <Navbar.return_link
          return_link={get_return_link(@lv_process, @in_iframe?)}
          class="hidden sm:block"
        />
        <NavigationMenu.dropdown
          return_link={get_return_link(@lv_process, @in_iframe?)}
          current_url={@url}
          class="sm:hidden"
        />
        <Navbar.live_debugger_logo_icon />
        <Navbar.connected id="navbar-connected" lv_process={@lv_process} />
        <div class="flex items-center gap-2">
          <Navbar.settings_button return_to={@url} />
          <span class="h-5 border-r border-default-border lg:hidden"></span>
          <.nav_icon
            phx-click={if @lv_process.ok?, do: JS.push("open-sidebar", target: "#sidebar")}
            class="flex lg:hidden"
            icon="icon-panel-right"
          />
        </div>
      </Navbar.navbar>
      <div class="flex overflow-hidden">
        <NavigationMenu.sidebar class="hidden sm:flex" current_url={@url} />
        <.async_result :let={lv_process} assign={@lv_process}>
          <:loading>
            <div class="m-auto flex items-center justify-center">
              <.spinner size="xl" />
            </div>
          </:loading>

          <div class="flex grow flex-col gap-4 p-8 overflow-y-auto max-w-screen-2xl mx-auto scrollbar-main">
            <StateLive.live_render
              id="node-state-lv"
              class="flex"
              socket={@socket}
              lv_process={lv_process}
              node_id={@node_id || lv_process.pid}
            />
            <TracesLive.live_render
              id="traces-list"
              class="flex"
              socket={@socket}
              lv_process={lv_process}
              node_id={@node_id || lv_process.pid}
              root_pid={self()}
            />
          </div>
          <SidebarLive.live_render
            id="sidebar"
            class="h-full"
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            node_id={@node_id || lv_process.pid}
          />
        </.async_result>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("find-successor", _, socket) do
    send(self(), :find_successor)

    {:noreply, socket}
  end

  defp assign_node_id(socket, %{"node_id" => node_id}) do
    case TreeNode.id_from_string(node_id) do
      {:ok, id} ->
        socket.id
        |> PubSubUtils.node_changed_topic()
        |> PubSubUtils.broadcast({:node_changed, id})

        assign(socket, :node_id, id)

      :error ->
        Logger.error("Invalid node_id: #{inspect(node_id)}")

        socket
        |> push_flash("Invalid `node_id` param")
        |> assign(:node_id, nil)
    end
  end

  defp assign_node_id(socket, _params) do
    assign(socket, :node_id, nil)
  end

  defp get_return_link(lv_process, in_iframe?) do
    cond do
      not in_iframe? ->
        RoutesHelper.live_views_dashboard()

      not lv_process.ok? ->
        nil

      in_iframe? ->
        RoutesHelper.window_dashboard(lv_process.result.transport_pid)
    end
  end
end
