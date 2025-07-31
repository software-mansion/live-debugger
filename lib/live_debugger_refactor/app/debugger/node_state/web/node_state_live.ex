defmodule LiveDebuggerRefactor.App.Debugger.NodeState.Web.NodeStateLive do
  @moduledoc """
  This LiveView displays the state of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.App.Debugger.Web.Helpers.NestedLiveView, as: NestedLiveViewHelper
  alias LiveDebuggerRefactor.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebuggerRefactor.App.Utils.TermParser
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.App.Debugger.NodeState.Queries, as: NodeStateQueries

  alias LiveDebuggerRefactor.Bus

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
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
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

    socket
    |> assign(:lv_process, lv_process)
    |> NestedLiveViewHelper.assign_node_id(session)
    |> assign_async_node_assigns()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={node_assigns} assign={@node_assigns}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="sm" />
          </div>
        </:loading>
        <:failed>
          <.alert class="w-full" with_icon heading="Error while fetching node state">
            Check logs for more
          </.alert>
        </:failed>

        <.assigns_section assigns={node_assigns} />
        <.fullscreen id="assigns-display-fullscreen" title="Assigns">
          <ElixirDisplay.term
            id="assigns-display-fullscreen-term"
            node={TermParser.term_to_display_tree(node_assigns)}
          />
        </.fullscreen>
      </.async_result>
    </div>
    """
  end

  attr(:assigns, :list, required: true)

  defp assigns_section(assigns) do
    ~H"""
    <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
      <:right_panel>
        <div class="flex gap-2">
          <.copy_button
            id="assigns"
            variant="icon-button"
            value={TermParser.term_to_copy_string(@assigns)}
          />
          <.fullscreen_button id="assigns-display-fullscreen" />
        </div>
      </:right_panel>
      <div class="relative w-full h-max max-h-full p-4 overflow-y-auto">
        <ElixirDisplay.term id="assigns-display" node={TermParser.term_to_display_tree(@assigns)} />
      </div>
    </.section>
    """
  end

  defp assign_async_node_assigns(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket
       )
       when not is_nil(node_id) do
    assign_async(socket, :node_assigns, fn ->
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  defp assign_async_node_assigns(socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
