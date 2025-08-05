defmodule LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web.ComponentsTreeLive do
  @moduledoc """
  Nested LiveView component that displays a tree of LiveView and LiveComponent nodes.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  require Logger

  alias Phoenix.Socket.Message
  alias LiveDebuggerRefactor.API.System.Process, as: ProcessAPI
  alias LiveDebugger.Utils.URL
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.App.Debugger.Web.Assigns.NestedLiveView, as: NestedLiveViewAssigns
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web.Components, as: TreeComponents
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Utils, as: ComponentsTreeUtils
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Queries, as: ComponentsTreeQueries

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentDeleted
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveComponentCreated

  @doc """
  Renders the `ComponentsTreeLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `params` - query parameters of the page.
  `url` - current URL of the page, used for patching
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:params, :map, required: true)
  attr(:url, :string, required: true)

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
      "url" => assigns.url
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]

    if connected?(socket) do
      Bus.receive_events!(lv_process.pid)
    end

    socket
    |> assign(lv_process: lv_process)
    |> assign(url: session["url"])
    |> assign(highlight?: false)
    |> NestedLiveViewAssigns.assign_node_id(session)
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
            :if={LiveDebuggerRefactor.Feature.enabled?(:highlighting)}
            id="highlight-switch"
            label="Highlight"
            checked={@highlight?}
            phx-click="toggle-highlight"
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
  def handle_info(%LiveComponentCreated{}, socket) do
    socket
    |> assign_async_tree()
    |> noreply()
  end

  def handle_info(%LiveComponentDeleted{}, socket) do
    socket
    |> assign_async_tree()
    |> noreply()
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.lv_process.pid
    assign_async(socket, [:tree], fn -> ComponentsTreeQueries.fetch_components_tree(pid) end)
  end

  defp highlight_element(
         %{assigns: %{highlight?: true, lv_process: %{pid: pid}}} = socket,
         %{"search-attribute" => attr, "search-value" => val}
       ) do
    send_event(pid, "highlight", %{attr: attr, val: val})
    socket
  end

  defp highlight_element(socket, _) do
    socket
  end

  defp pulse_element(socket, %{"search-attribute" => attr, "search-value" => val}) do
    if LiveDebugger.Feature.enabled?(:highlighting) do
      # Resets the highlight when the user selects node
      if socket.assigns.highlight? do
        send_event(socket.assigns.lv_process.pid, "highlight", %{attr: attr, val: val})
      end

      send_event(socket.assigns.lv_process.pid, "pulse", %{attr: attr, val: val})
    end

    socket
  end

  defp send_event(pid, event, payload) do
    {:ok, state} = ProcessAPI.state(pid)

    message = %Message{
      topic: state.topic,
      event: "diff",
      payload: %{e: [[event, payload]]},
      join_ref: state.join_ref
    }

    send(state.socket.transport_pid, state.serializer.encode!(message))
  end
end
