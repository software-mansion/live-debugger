defmodule LiveDebugger.App.Debugger.Web.DebuggerLive do
  @moduledoc """
  Main page of the LiveDebugger.
  It contains many components to debug the LiveView process.
  When DeadViewMode is enabled it will also allow to debug process even after the LiveView is dead.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Debugger.Web.Hooks
  alias LiveDebugger.App.Debugger.Web.HookComponents
  alias LiveDebugger.App.Debugger.Web.Components.NavigationMenu
  alias LiveDebugger.App.Debugger.Web.Components.Pages
  alias LiveDebugger.App.Web.Components.Navbar
  alias LiveDebugger.App.Debugger.Web.HookComponents
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.Bus

  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.App.Events.DebuggerTerminated

  @impl true
  def mount(%{"pid" => string_pid}, _session, socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    string_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, pid} ->
        init_debugger(socket, pid)

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
          <Navbar.return_link return_link={RoutesHelper.discovery()} class="hidden sm:block" />
          <NavigationMenu.dropdown
            return_link={RoutesHelper.discovery()}
            current_url={@url}
            class="sm:hidden"
          />
          <Navbar.live_debugger_logo_icon />
          <HookComponents.DeadViewMode.render id="navbar-connected" lv_process={lv_process} />
          <div class="flex items-center gap-2">
            <HookComponents.InspectButton.render
              inspect_mode?={@inspect_mode?}
              lv_process={lv_process}
            />
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
            root_socket_id={@root_socket_id}
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

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def terminate(_, _) do
    Bus.broadcast_event!(%DebuggerTerminated{
      debugger_pid: self()
    })
  end

  defp init_debugger(socket, pid) when is_pid(pid) do
    socket
    |> Hooks.AsyncLvProcess.init(pid)
    |> put_private(:pid, pid)
    |> HookComponents.DeadViewMode.init()
    |> HookComponents.InspectButton.init()
  end

  defp assign_and_broadcast_node_id(socket, %{"node_id" => node_id}) do
    socket_node_id = socket.assigns[:node_id]

    node_id
    |> TreeNode.id_from_string()
    |> case do
      {:ok, ^socket_node_id} ->
        Pages.close_node_inspector_sidebar()
        socket

      {:ok, node_id} ->
        Bus.broadcast_event!(%NodeIdParamChanged{node_id: node_id, debugger_pid: self()}, self())
        Pages.close_node_inspector_sidebar()

        assign(socket, :node_id, node_id)

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_node_id"))
    end
  end

  defp assign_and_broadcast_node_id(socket, _) do
    assign(socket, :node_id, socket.private.pid)
  end
end
