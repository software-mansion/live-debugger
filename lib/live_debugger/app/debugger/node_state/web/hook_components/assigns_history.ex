defmodule LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsHistory do
  @moduledoc """
  This component is used to add node assigns history functionality.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.App.Debugger.NodeState.Web.Components, as: NodeStateComponents
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.API.TracesStorage
  alias Phoenix.LiveView.AsyncResult

  @required_assigns [:node_id, :lv_process]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:assigns_history, :handle_event, &handle_event/3)
    |> attach_hook(:assigns_history, :handle_async, &handle_async/3)
    |> attach_hook(:assigns_history, :handle_info, &handle_info/2)
    |> register_hook(:assigns_history)
    |> put_private(:opened?, false)
    |> assign(:current_history_index, 0)
    |> assign(:history_length, 0)
    |> assign(:history_entries, AsyncResult.loading())
  end

  attr(:current_history_index, :integer, required: true)
  attr(:history_entries, AsyncResult, required: true)
  attr(:history_length, :integer, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.fullscreen id="assigns-history" title="Assigns History" class="xl:w-3/4!">
      <div class="flex flex-col justify-between p-4 min-h-[40rem]">
        <.async_result :let={history_entries} assign={@history_entries}>
          <:loading>
            <NodeStateComponents.loading />
          </:loading>
          <:failed>
            <NodeStateComponents.failed />
          </:failed>

          <div class="flex flex-grow justify-center items-center gap-2 mb-4">
            <div class="max-w-1/2 overflow-x-auto">
              <ElixirDisplay.static_term
                :if={history_entries.old != nil}
                id="assigns-display-fullscreen-term-2"
                node={history_entries.old |> elem(1)}
                click_event="toggle_diff_node"
                diff={history_entries.diff}
                diff_class="bg-diff-negative-bg"
              />
            </div>
            <div class="max-w-1/2 overflow-x-auto">
              <ElixirDisplay.static_term
                id="assigns-display-fullscreen-term-3"
                node={history_entries.new |> elem(1)}
                click_event="toggle_diff_node"
                diff={history_entries.diff}
                diff_class="bg-diff-positive-bg"
              />
            </div>
          </div>
        </.async_result>
        <NodeStateComponents.assigns_history_navigation
          disabled?={not @history_entries.ok?}
          index={@current_history_index}
          length={@history_length}
        />
      </div>
    </.fullscreen>
    """
  end

  def button(assigns) do
    ~H"""
    <.fullscreen_button id="assigns-history" icon="icon-history" phx-click="open-assigns-history" />
    """
  end

  defp handle_event("open-assigns-history", _params, socket) do
    socket
    |> assign_async_assigns_history()
    |> push_event("assigns-history-open", %{})
    |> halt()
  end

  defp handle_event("go-back", _, socket) do
    new_index = min(socket.assigns.current_history_index + 1, socket.assigns.history_length - 1)

    socket
    |> assign(:current_history_index, new_index)
    |> assign_async_assigns_history()
    |> halt()
  end

  defp handle_event("go-back-end", _, socket) do
    socket
    |> assign(:current_history_index, socket.assigns.history_length - 1)
    |> assign_async_assigns_history()
    |> halt()
  end

  defp handle_event("go-forward", _, socket) do
    new_index = max(socket.assigns.current_history_index - 1, 0)

    socket
    |> assign(:current_history_index, new_index)
    |> assign_async_assigns_history()
    |> halt()
  end

  defp handle_event("go-forward-end", _, socket) do
    socket
    |> assign(:current_history_index, 0)
    |> assign_async_assigns_history()
    |> halt()
  end

  defp handle_event("toggle_diff_node", %{"id" => id}, socket) do
    case socket.assigns.history_entries do
      %AsyncResult{result: %{new: new, old: old} = result} ->
        new = toggle_term_node_in_history_entry(new, id)
        old = toggle_term_node_in_history_entry(old, id)

        socket
        |> assign(:history_entries, AsyncResult.ok(%{result | new: new, old: old}))

      _ ->
        socket
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_async(:fetch_history_entries, {:ok, {:ok, {entries, length}}}, socket) do
    socket
    |> assign(history_length: length)
    |> assign_async(:history_entries, fn ->
      case entries do
        {new_assigns, old_assigns} ->
          new = {new_assigns, TermParser.term_to_display_tree(new_assigns)}
          old = {old_assigns, TermParser.term_to_display_tree(old_assigns)}
          diff = TermDiffer.diff(old_assigns, new_assigns)

          {:ok, %{history_entries: %{new: new, old: old, diff: diff}}}

        {initial_assigns} ->
          new = {initial_assigns, TermParser.term_to_display_tree(initial_assigns)}

          {:ok, %{history_entries: %{new: new, old: nil, diff: nil}}}
      end
    end)
    |> halt()
  end

  defp handle_async(:fetch_history_entries, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:history_entries, AsyncResult.failed(socket.assigns.history_entries, reason))
    |> halt()
  end

  defp handle_async(:fetch_history_entries, {:exit, reason}, socket) do
    socket
    |> assign(:history_entries, AsyncResult.failed(socket.assigns.history_entries, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_assigns_history()
    |> cont()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp assign_async_assigns_history(
         %{
           assigns: %{
             current_history_index: index,
             node_id: node_id,
             lv_process: %{pid: pid}
           }
         } = socket
       ) do
    socket
    |> assign(history_entries: AsyncResult.loading())
    |> start_async(:fetch_history_entries, fn ->
      NodeStateQueries.fetch_assigns_history_entries(pid, node_id, index)
    end)
  end

  defp toggle_term_node_in_history_entry(nil, _id), do: nil

  defp toggle_term_node_in_history_entry({assigns, term_node}, id) do
    {assigns, maybe_toggle_term_node_by_id(term_node, id)}
  end

  defp maybe_toggle_term_node_by_id(term_node, id) do
    term_node
    |> TermParser.update_by_id(id, fn %TermNode{} = term_node ->
      %TermNode{term_node | open?: !term_node.open?}
    end)
    |> case do
      {:ok, updated_term_node} -> updated_term_node
      {:error, _reason} -> term_node
    end
  end
end
