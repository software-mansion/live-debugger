defmodule LiveDebugger.App.Debugger.ComponentsTree.Web.ComponentsTreeLive do
  @moduledoc """
  Nested LiveView component that displays a tree of LiveView and LiveComponent nodes.
  """

  use LiveDebugger.App.Web, :live_view

  require Logger

  alias LiveDebugger.Client
  alias LiveDebugger.App.Utils.URL
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.ComponentsTree.Web.Components, as: TreeComponents
  alias LiveDebugger.App.Debugger.ComponentsTree.Utils, as: ComponentsTreeUtils
  alias LiveDebugger.App.Debugger.ComponentsTree.Queries, as: ComponentsTreeQueries
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveComponentCreated
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered

  @doc """
  Renders the `ComponentsTreeLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `node_id` - node id of the currently selected node
  `url` - current URL of the page, used for patching
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:root_socket_id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:url, :string, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the wrapper div")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "root_socket_id" => assigns.root_socket_id,
      "url" => assigns.url,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session, container: {:div, class: @class}) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    parent_pid = session["parent_pid"]

    if connected?(socket) do
      Bus.receive_events!(lv_process.pid)
      Bus.receive_events!(parent_pid)
    end

    socket
    |> assign(lv_process: lv_process)
    |> assign(parent_pid: parent_pid)
    |> assign(node_id: session["node_id"])
    |> assign(root_socket_id: session["root_socket_id"])
    |> assign(url: session["url"])
    |> assign(highlight?: false)
    |> assign(highlight_disabled?: !lv_process.alive?)
    |> assign_async_tree()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner size="sm" /></div>
      </:loading>
      <:failed :let={_error}>
        <.alert>Couldn't load a tree</.alert>
      </:failed>
      <div class="min-h-20 px-1 overflow-y-auto overflow-x-hidden flex flex-col">
        <div class="flex items-center justify-between">
          <div class="shrink-0 font-medium text-secondary-text px-6 py-3">Components Tree</div>
          <.toggle_switch
            :if={LiveDebugger.Feature.enabled?(:highlighting)}
            id="highlight-switch"
            label="Highlight"
            checked={@highlight?}
            phx-click="toggle-highlight"
            disabled={@highlight_disabled?}
          />
        </div>
        <div class="flex-1">
          <TreeComponents.tree_node
            id="components-tree"
            tree_node={tree}
            selected_node_id={@node_id}
            max_opened_node_level={ComponentsTreeUtils.max_opened_node_level(tree)}
          />
        </div>
      </div>
    </.async_result>
    """
  end

  @impl true
  def handle_event("toggle-highlight", _params, socket) do
    socket
    |> update(:highlight?, &(not &1))
    |> noreply()
  end

  def handle_event("highlight", params, socket) do
    socket
    |> highlight_element(params)
    |> noreply()
  end

  def handle_event("select_node", %{"node-id" => node_id} = params, socket) do
    socket
    |> pulse_element(params)
    |> push_patch(to: URL.upsert_query_param(socket.assigns.url, "node_id", node_id))
    |> assign(:highlight?, false)
    |> noreply()
  end

  @impl true
  def handle_info(
        %LiveComponentCreated{pid: pid},
        %{assigns: %{lv_process: %{pid: pid}}} = socket
      ) do
    socket
    |> assign_async_tree()
    |> noreply()
  end

  def handle_info(
        %LiveComponentDeleted{pid: pid},
        %{assigns: %{lv_process: %{pid: pid}}} = socket
      ) do
    socket
    |> assign_async_tree()
    |> noreply()
  end

  def handle_info(
        %NodeIdParamChanged{node_id: node_id, debugger_pid: pid},
        %{assigns: %{parent_pid: pid}} = socket
      ) do
    socket
    |> assign(node_id: node_id)
    |> noreply()
  end

  def handle_info(
        %DeadViewModeEntered{debugger_pid: pid},
        %{assigns: %{parent_pid: pid}} = socket
      ) do
    socket
    |> assign(highlight_disabled?: true)
    |> assign(highlight?: false)
    |> noreply()
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.lv_process.pid
    assign_async(socket, [:tree], fn -> ComponentsTreeQueries.fetch_components_tree(pid) end)
  end

  defp highlight_element(
         %{assigns: %{highlight_disabled?: false, highlight?: true}} = socket,
         params
       ) do
    payload = %{
      attr: params["search-attribute"],
      val: params["search-value"],
      type: if(params["type"] == "live_view", do: "LiveView", else: "LiveComponent"),
      module: Parsers.module_to_string(params["module"]),
      id_value: params["id"],
      id_key: if(params["type"] == "live_view", do: "PID", else: "CID")
    }

    Client.push_event!(socket.assigns.root_socket_id, "highlight", payload)

    socket
  end

  defp highlight_element(socket, _) do
    socket
  end

  defp pulse_element(%{assigns: %{highlight_disabled?: true}} = socket, _) do
    socket
  end

  defp pulse_element(socket, params) do
    if LiveDebugger.Feature.enabled?(:highlighting) do
      # Resets the highlight when the user selects node
      if socket.assigns.highlight? do
        Client.push_event!(socket.assigns.root_socket_id, "highlight")
      end

      payload = %{
        attr: params["search-attribute"],
        val: params["search-value"],
        type: if(params["type"] == "live_view", do: "LiveView", else: "LiveComponent")
      }

      Client.push_event!(socket.assigns.root_socket_id, "pulse", payload)
    end

    socket
  end
end
