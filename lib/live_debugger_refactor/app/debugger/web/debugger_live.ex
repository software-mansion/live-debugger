defmodule LiveDebuggerRefactor.App.Debugger.Web.DebuggerLive do
  @moduledoc """
  Main page of the LiveDebugger.
  It contains many components to debug the LiveView process.
  When DeadViewMode is enabled it will also allow to debug process even after the LiveView is dead.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  alias LiveDebuggerRefactor.App.Debugger.Web.Hooks
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.App.Debugger.Structs.TreeNode
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebuggerRefactor.App.Debugger.Web.Components.Pages
  alias LiveDebuggerRefactor.App.Web.Components.Navbar
  alias LiveDebuggerRefactor.App.Debugger.Web.Components.NavigationMenu

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Debugger.Events.NodeIdParamChanged

  @impl true
  def mount(%{"pid" => string_pid}, _session, socket) do
    string_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, pid} ->
        socket
        |> Hooks.AsyncLvProcess.init(pid)
        |> assign(:pid, pid)

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_pid"))
    end
    |> ok()
  end

  @impl true
  def handle_params(params, _url, socket) do
    socket
    |> assign_and_broadcast_node_id(params)
    |> noreply()
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
              phx-click={if @lv_process.ok?, do: Pages.get_open_sidebar_js(@live_action)}
              class="flex lg:hidden"
              icon="icon-panel-right"
            />
          </div>
        </Navbar.navbar>
        <div class="flex overflow-hidden w-full">
          <NavigationMenu.sidebar class="hidden sm:flex" current_url={@url} />
          <Pages.node_inspector
            :if={@live_action == :node_inspector}
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            node_id={@node_id}
          />
          <Pages.global_traces
            :if={@live_action == :global_traces}
            socket={@socket}
            lv_process={lv_process}
          />
        </div>
      </.async_result>
    </div>
    """
  end

  defp assign_and_broadcast_node_id(socket, %{"node_id" => node_id}) do
    node_id
    |> TreeNode.id_from_string()
    |> case do
      {:ok, node_id} ->
        Bus.broadcast_event!(%NodeIdParamChanged{node_id: node_id, debugger_pid: self()}, self())
        Pages.close_node_inspector_sidebar()

        assign(socket, :node_id, node_id)

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_node_id"))
    end
  end

  defp assign_and_broadcast_node_id(socket, _) do
    assign(socket, :node_id, socket.assigns.pid)
  end

  defp get_return_link(lv_process, in_iframe?) do
    cond do
      not in_iframe? ->
        RoutesHelper.discovery()

      in_iframe? ->
        RoutesHelper.discovery(lv_process.transport_pid)
    end
  end
end
