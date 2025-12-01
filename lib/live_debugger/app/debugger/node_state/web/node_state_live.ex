defmodule LiveDebugger.App.Debugger.NodeState.Web.NodeStateLive do
  @moduledoc """
  This LiveView displays the state of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.NodeState.Web.Hooks
  alias LiveDebugger.App.Debugger.NodeState.Web.HookComponents
  alias LiveDebugger.App.Debugger.NodeState.Web.Components, as: NodeStateComponents

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

  alias Phoenix.LiveView.AsyncResult

  @doc """
  Renders the `NodeStateLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `params` - query parameters of the page.
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:node_id, :any, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    parent_pid = session["parent_pid"]
    node_id = session["node_id"]

    if connected?(socket) do
      Bus.receive_events!(parent_pid)
      Bus.receive_states!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> assign(:assigns_search_phrase, "")
    |> Hooks.NodeAssigns.init()
    |> Hooks.TermNodeToggle.init()
    |> HookComponents.AssignsSearch.init()
    |> HookComponents.AssignsHistory.init()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 w-full flex flex-col gap-4">
      <.async_result :let={{_node_assigns, term_node, copy_string}} assign={@node_assigns_info}>
        <:loading>
          <NodeStateComponents.loading />
        </:loading>
        <:failed>
          <NodeStateComponents.failed />
        </:failed>

        <NodeStateComponents.assigns_section
          term_node={term_node}
          copy_string={copy_string}
          fullscreen_id="assigns-display-fullscreen"
          assigns_sizes={@assigns_sizes}
          pinned_assigns={@pinned_assigns}
          assigns_search_phrase={@assigns_search_phrase}
          node_assigns_status={assigns_status(@lv_process, @node_assigns_info)}
        />
        <HookComponents.AssignsHistory.render
          current_history_index={@current_history_index}
          history_entries={@history_entries}
          history_length={@history_length}
        />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("pin-assign", %{"key" => key}, socket) do
    pinned_assigns = %{socket.assigns.pinned_assigns | key => true}

    socket
    |> assign(:pinned_assigns, pinned_assigns)
    |> noreply()
  end

  def handle_event("unpin-assign", %{"key" => key}, socket) do
    pinned_assigns = %{socket.assigns.pinned_assigns | key => false}

    socket
    |> assign(:pinned_assigns, pinned_assigns)
    |> noreply()
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> Hooks.NodeAssigns.assign_async_node_assigns(reset: true)
    |> noreply()
  end

  def handle_info(%StateChanged{}, socket) do
    socket
    |> Hooks.NodeAssigns.assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%DeadViewModeEntered{}, socket) do
    socket
    |> assign(:lv_process, LvProcess.set_alive(socket.assigns.lv_process, false))
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assigns_status(%LvProcess{alive?: false}, _), do: :disconnected
  defp assigns_status(_, %AsyncResult{loading: [stage: :update]}), do: :updating
  defp assigns_status(_, %AsyncResult{ok?: true}), do: :loaded
  defp assigns_status(_, _), do: :error
end
