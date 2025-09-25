defmodule LiveDebugger.App.Debugger.NodeState.Web.NodeStateLive do
  @moduledoc """
  This LiveView displays the state of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.NodeState.Web.Components, as: NodeStateComponents
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.App.Debugger.NodeState.Utils, as: NodeStateUtils

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

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
    |> assign(:assigns_history_pointer, 0)
    |> assign_async_node_assigns()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={node_assigns} assign={@node_assigns}>
        <:loading>
          <NodeStateComponents.loading />
        </:loading>
        <:failed>
          <NodeStateComponents.failed />
        </:failed>

        <NodeStateComponents.assigns_section
          assigns={node_assigns}
          fullscreen_id="assigns-display-fullscreen"
        />
        <.fullscreen id="assigns-history" title="Assigns History">
          <div class="p-4">
            <div class="flex justify-center items-center gap-4 mb-4">
              <.icon_button
                variant="secondary"
                icon="icon-chevron-right"
                phx-click="go-back-in-history"
                disabled={@assigns_history_pointer == length(@assigns_history.result) - 2}
                class="rotate-180 disabled:pointer-events-none disabled:opacity-50"
              />
              <span>
                <%= @assigns_history_pointer + 1 %> / <%= length(@assigns_history.result) - 1 %>
              </span>
              <.icon_button
                variant="secondary"
                icon="icon-chevron-right"
                phx-click="go-forward-in-history"
                disabled={@assigns_history_pointer == 0}
                class="disabled:pointer-events-none disabled:opacity-50"
              />
            </div>
            <div class="flex justify-center gap-2 mb-4">
              <%= if length(@assigns_history.result) > 1 do %>
                <div class="max-w-1/2 overflow-x-auto">
                  <ElixirDisplay.term
                    id="assigns-display-fullscreen-term-2"
                    diff_color="diff-removed-bg"
                    node={
                      TermParser.term_to_display_tree(
                        @assigns_history.result
                        |> Enum.at(@assigns_history_pointer + 1),
                        NodeStateUtils.diff(
                          Enum.at(@assigns_history.result, @assigns_history_pointer + 1),
                          Enum.at(@assigns_history.result, @assigns_history_pointer)
                        )
                      )
                    }
                  />
                </div>
                <div class="max-w-1/2 overflow-x-auto">
                  <ElixirDisplay.term
                    id="assigns-display-fullscreen-term-3"
                    diff_color="diff-added-bg"
                    node={
                      TermParser.term_to_display_tree(
                        @assigns_history.result
                        |> Enum.at(@assigns_history_pointer),
                        NodeStateUtils.diff(
                          Enum.at(@assigns_history.result, @assigns_history_pointer + 1),
                          Enum.at(@assigns_history.result, @assigns_history_pointer)
                        )
                      )
                    }
                  />
                </div>
              <% end %>
            </div>
          </div>
        </.fullscreen>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("go-back-in-history", _, socket) do
    history_length = length(socket.assigns.assigns_history.result)
    new_pointer = min(socket.assigns.assigns_history_pointer + 1, history_length - 2)

    socket
    |> assign(:assigns_history_pointer, new_pointer)
    |> noreply()
  end

  def handle_event("go-forward-in-history", _, socket) do
    new_pointer = max(socket.assigns.assigns_history_pointer - 1, 0)

    socket
    |> assign(:assigns_history_pointer, new_pointer)
    |> noreply()
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_node_assigns(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
       when not is_nil(node_id) do
    assign_async(socket, [:node_assigns, :assigns_history], fn ->
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  defp assign_async_node_assigns(socket) do
    assign(socket, :node_assigns, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
