defmodule LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsHistory do
  @moduledoc """
  This component is used to add node assigns history functionality.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged
  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.API.TracesStorage
  alias Phoenix.LiveView.AsyncResult

  @required_assigns [:node_id, :lv_process]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:assigns_history, :handle_event, &handle_event/3)
    |> attach_hook(:assigns_history, :handle_info, &handle_info/2)
    |> register_hook(:assigns_history)
    |> put_private(:opened?, false)
    |> assign(:current_history_index, 0)
    |> assign(:history_entries, AsyncResult.loading())
    |> assign(:history_length, AsyncResult.loading())
  end

  attr(:current_history_index, :integer, required: true)
  attr(:history_entries, AsyncResult, required: true)
  attr(:history_length, AsyncResult, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.fullscreen id="assigns-history" title="Assigns History" class="xl:w-3/4!">
      <div class="flex flex-col p-4 min-h-[40rem]">
        <.async_result :let={history_entries} assign={@history_entries}>
          <:loading>
            <div class="w-full flex-grow flex items-center justify-center">
              <.spinner size="sm" />
            </div>
          </:loading>
          <:failed>
            <.alert class="w-full" with_icon heading="Error while fetching node state">
              Check logs for more
            </.alert>
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
        <.navigation_buttons
          loading={@history_entries.loading}
          index={@current_history_index}
          length={@history_length.result || 0}
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

  attr(:loading, :boolean, required: true)
  attr(:index, :integer, required: true)
  attr(:length, :integer, required: true)

  defp navigation_buttons(assigns) do
    ~H"""
    <div class="flex justify-end items-center gap-2 mb-4">
      <.icon_button
        variant="secondary"
        icon="icon-chevrons-right"
        phx-click="go-back-end"
        class="rotate-180"
        disabled={if(@loading || @index == @length - 1, do: true)}
      />
      <.icon_button
        variant="secondary"
        icon="icon-chevron-right"
        phx-click="go-back"
        class="rotate-180"
        disabled={if(@loading || @index == @length - 1, do: true)}
      />
      <span>
        <%= @index + 1 %> / <%= @length %>
      </span>
      <.icon_button
        variant="secondary"
        icon="icon-chevron-right"
        phx-click="go-forward"
        disabled={if(@loading || @index == 0, do: true)}
      />
      <.icon_button
        variant="secondary"
        icon="icon-chevrons-right"
        phx-click="go-forward-end"
        disabled={if(@loading || @index == 0, do: true)}
      />
    </div>
    """
  end

  defp handle_event("open-assigns-history", _params, socket) do
    socket
    |> assign_async_assigns_history()
    |> push_event("assigns-history-open", %{})
    |> halt()
  end

  defp handle_event("go-back", _, socket) do
    new_index =
      min(socket.assigns.current_history_index + 1, socket.assigns.history_length.result - 1)

    socket
    |> assign(:current_history_index, new_index)
    |> assign_async_assigns_history()
    |> halt()
  end

  defp handle_event("go-back-end", _, socket) do
    socket
    |> assign(:current_history_index, socket.assigns.history_length.result - 1)
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
        new = put_elem(new, 1, maybe_open_term_node_by_id(elem(new, 1), id))

        old =
          case old do
            nil -> nil
            _ -> put_elem(old, 1, maybe_open_term_node_by_id(elem(old, 1), id))
          end

        socket
        |> assign(:history_entries, AsyncResult.ok(%{result | new: new, old: old}))

      _ ->
        socket
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_assigns_history()
    |> cont()
  end

  defp maybe_open_term_node_by_id(term_node, id) do
    term_node
    |> TermParser.update_by_id(id, fn %TermNode{} = term_node ->
      %TermNode{term_node | open?: !term_node.open?}
    end)
    |> case do
      {:ok, updated_term_node} -> updated_term_node
      {:error, _reason} -> term_node
    end
  end

  defp assign_async_assigns_history(socket)

  # defp assign_async_assigns_history(
  #        %{
  #          assigns: %{
  #            current_history_index: index,
  #            node_id: node_id,
  #            lv_process: lv_process,
  #            history_entries: %AsyncResult{ok?: true, result: %{new: new, old: nil}}
  #          }
  #        } = socket,
  #        opts
  #      ) do
  #   assign_async(
  #     socket,
  #     [:history_entries, :history_length],
  #     fn ->
  #       case fetch_history_entries(lv_process.pid, node_id, index) do
  #         nil ->
  #           {:error, :no_history_record}
  #
  #         {new_new_assigns, new_old_assigns, history_length} ->
  #           {new_assigns, new_term_node} = new
  #
  #           with {:ok, new_term_node} <-
  #                  update_term_node(new_term_node, new_assigns, new_new_assigns) do
  #             new = {new_new_assigns, new_term_node}
  #             old = {new_old_assigns, TermParser.term_to_display_tree(new_old_assigns)}
  #             diff = TermDiffer.diff(new_old_assigns, new_new_assigns)
  #
  #             {:ok,
  #              %{
  #                history_entries: %{new: new, old: old, diff: diff},
  #                history_length: history_length
  #              }}
  #           else
  #             {:error, reason} -> {:error, reason}
  #           end
  #
  #         {new_new_assigns, history_length} ->
  #           {new_assigns, new_term_node} = new
  #
  #           with {:ok, new_term_node} <-
  #                  update_term_node(new_term_node, new_assigns, new_new_assigns) do
  #             new = {new_new_assigns, new_term_node}
  #
  #             {:ok,
  #              %{
  #                history_entries: %{new: new, old: nil, diff: nil},
  #                history_length: history_length
  #              }}
  #           else
  #             {:error, reason} -> {:error, reason}
  #           end
  #       end
  #     end,
  #     opts
  #   )
  # end

  # defp assign_async_assigns_history(
  #        %{
  #          assigns: %{
  #            current_history_index: index,
  #            node_id: node_id,
  #            lv_process: lv_process,
  #            history_entries: %AsyncResult{ok?: true, result: %{new: new, old: old}}
  #          }
  #        } = socket,
  #        opts
  #      ) do
  #   assign_async(
  #     socket,
  #     [:history_entries, :history_length],
  #     fn ->
  #       case fetch_history_entries(lv_process.pid, node_id, index) do
  #         nil ->
  #           {:error, :no_history_record}
  #
  #         {new_new_assigns, new_old_assigns, history_length} ->
  #           {new_assigns, new_term_node} = new
  #           {old_assigns, old_term_node} = old
  #
  #           with {:ok, new_term_node} <-
  #                  update_term_node(new_term_node, new_assigns, new_new_assigns),
  #                {:ok, old_term_node} <-
  #                  update_term_node(old_term_node, old_assigns, new_old_assigns) do
  #             new = {new_new_assigns, new_term_node}
  #             old = {new_old_assigns, old_term_node}
  #             diff = TermDiffer.diff(new_old_assigns, new_new_assigns)
  #
  #             {:ok,
  #              %{
  #                history_entries: %{new: new, old: old, diff: diff},
  #                history_length: history_length
  #              }}
  #           else
  #             {:error, reason} -> {:error, reason}
  #           end
  #
  #         {new_new_assigns, history_length} ->
  #           {new_assigns, new_term_node} = new
  #
  #           with {:ok, new_term_node} <-
  #                  update_term_node(new_term_node, new_assigns, new_new_assigns) do
  #             new = {new_new_assigns, new_term_node}
  #
  #             {:ok,
  #              %{
  #                history_entries: %{new: new, old: nil, diff: nil},
  #                history_length: history_length
  #              }}
  #           else
  #             {:error, reason} -> {:error, reason}
  #           end
  #       end
  #     end,
  #     opts
  #   )
  # end

  defp assign_async_assigns_history(
         %{
           assigns: %{
             current_history_index: index,
             node_id: node_id,
             lv_process: lv_process
           }
         } = socket
       ) do
    assign_async(
      socket,
      [:history_entries, :history_length],
      fn ->
        case fetch_history_entries(lv_process.pid, node_id, index) do
          nil ->
            {:error, :no_history_record}

          {new_assigns, old_assigns, history_length} ->
            new = {new_assigns, TermParser.term_to_display_tree(new_assigns)}
            old = {old_assigns, TermParser.term_to_display_tree(old_assigns)}
            diff = TermDiffer.diff(old_assigns, new_assigns)

            {:ok,
             %{history_entries: %{new: new, old: old, diff: diff}, history_length: history_length}}

          {initial_assigns, history_length} ->
            new = {initial_assigns, TermParser.term_to_display_tree(initial_assigns)}

            {:ok,
             %{history_entries: %{new: new, old: nil, diff: nil}, history_length: history_length}}
        end
      end,
      reset: true
    )
  end

  defp fetch_history_entries(pid, node_id, index) do
    case TracesStorage.get!(pid, functions: ["render/1"], node_id: node_id) do
      :end_of_table ->
        nil

      {render_traces, _} ->
        render_traces
        |> Enum.slice(index, 2)
        |> Enum.map(&(&1.args |> hd() |> Map.delete(:socket)))
        |> case do
          [new_assigns, old_assigns] ->
            {new_assigns, old_assigns, length(render_traces)}

          [initial_assigns] ->
            {initial_assigns, length(render_traces)}
        end
    end
  end

  # defp update_term_node(term_node, old_term, new_term) do
  #   case TermDiffer.diff(old_term, new_term) do
  #     %Diff{type: :equal} ->
  #       {:ok, term_node}
  #
  #     diff ->
  #       term_node
  #       |> TermParser.update_by_diff(diff)
  #       |> case do
  #         {:ok, term_node} ->
  #           term_node =
  #             TermNode.open_with_default_settings(term_node)
  #             |> TermNode.set_pulse(false, recursive: true)
  #
  #           {:ok, term_node}
  #
  #         {:error, reason} ->
  #           {:error, reason}
  #       end
  #   end
  # end
end
