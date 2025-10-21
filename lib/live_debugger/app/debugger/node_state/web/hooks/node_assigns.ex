defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.NodeAssigns do
  @moduledoc """
  This hook is responsible for fetching assigns of specific node.
  """

  use LiveDebugger.App.Web, :hook

  alias LiveDebugger.App.Utils.TermNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser

  @required_assigns [
    :node_id,
    :lv_process,
    :assigns_search_phrase
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:node_assigns, :handle_async, &handle_async/3)
    |> register_hook(:node_assigns)
    |> assign(:node_assigns_info, AsyncResult.loading())
    |> assign_async_node_assigns()
  end

  def update_with_search_phrase(socket) do
    {node_assigns, term_node, copy_string} = socket.assigns.node_assigns_info.result

    term_node =
      term_node
      |> TermNode.open_with_search_phrase(socket.assigns.assigns_search_phrase)

    node_assigns_info = AsyncResult.ok({node_assigns, term_node, copy_string})

    socket
    |> assign(:node_assigns_info, node_assigns_info)
  end

  @doc """
  Assigns the async node assigns to the socket.

  ## Options

  - `:reset` - If `true`, assigns won't diff current assigns with new ones.
  """
  @spec assign_async_node_assigns(Phoenix.LiveView.Socket.t(), Keyword.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_async_node_assigns(socket, opts \\ [])

  def assign_async_node_assigns(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        opts
      )
      when not is_nil(node_id) do
    dbg(:assign)

    node_assigns_info =
      if Keyword.get(opts, :reset, false) do
        AsyncResult.loading()
      else
        socket.assigns.node_assigns_info
      end

    socket
    |> assign(:node_assigns_info, node_assigns_info)
    |> start_async(:fetch_node_assigns, fn ->
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  def assign_async_node_assigns(socket, _) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp handle_async(
         :fetch_node_assigns,
         {:ok, {:ok, node_assigns}},
         %{
           assigns: %{
             node_assigns_info: %AsyncResult{ok?: true, result: {old_assigns, old_term_node, _}}
           }
         } =
           socket
       ) do
    node_assigns_info =
      case TermDiffer.diff(old_assigns, node_assigns) do
        %Diff{type: :equal} ->
          {node_assigns, term_node, copy_string} = socket.assigns.node_assigns_info.result

          # term_node =
          #   term_node
          #   |> TermNode.open_with_search_phrase(socket.assigns.assigns_search_phrase)

          AsyncResult.ok({node_assigns, term_node, copy_string})

        diff ->
          copy_string = TermParser.term_to_copy_string(node_assigns)

          case TermParser.update_by_diff(old_term_node, diff) do
            {:ok, term_node} ->
              # term_node =
              #   term_node
              #   |> TermNode.open_with_search_phrase(socket.assigns.assigns_search_phrase)

              AsyncResult.ok({node_assigns, term_node, copy_string})

            {:error, reason} ->
              AsyncResult.failed(socket.assigns.node_assigns_info, reason)
          end
      end

    socket
    |> assign(:node_assigns_info, node_assigns_info)
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:ok, node_assigns}}, socket) do
    term_node =
      TermParser.term_to_display_tree(node_assigns)

    # |> TermNode.open_with_search_phrase(socket.assigns.assigns_search_phrase)

    copy_string = TermParser.term_to_copy_string(node_assigns)

    socket
    |> assign(:node_assigns_info, AsyncResult.ok({node_assigns, term_node, copy_string}))
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.node_assigns_info, reason))
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:exit, reason}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.node_assigns_info, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
