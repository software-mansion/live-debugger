defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.NodeStreams do
  @moduledoc """
  This hook is responsible for fetching streams of specific node.
  """

  use LiveDebugger.App.Web, :hook

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser

  @required_assigns [
    :node_id,
    :lv_process
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:node_streams, :handle_async, &handle_async/3)
    |> register_hook(:node_streams)
    |> assign(:streams_state, AsyncResult.loading())
    |> assign_async_node_streams()
  end

  @doc """
  Assigns the async node streams to the socket.
  """

  # @spec assign_async_node_streams(Phoenix.LiveView.Socket.t()::
  #         Phoenix.LiveView.Socket.t()
  # def assign_async_node_assigns(socket, opts \\ [])

  def assign_async_node_streams(%{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket)
      when not is_nil(node_id) do
    socket
    |> start_async(:fetch_node_streams, fn ->
      # to musi zwrocic diffa zebranego z wszydtkich render tracow
      NodeStateQueries.fetch_node_streams(pid)
    end)
  end

  def assign_async_node_streams(socket) do
    assign(socket, :streams, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  def assign_async_node_streams(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        updated_streams
      )
      when not is_nil(node_id) do
    case Map.get(socket.assigns, :streams_state_list, nil) do
      nil ->
        assign_async_node_streams(socket)

      current_streams_state ->
        socket
        |> start_async(:fetch_node_streams, fn ->
          NodeStateQueries.update_node_streams(pid, updated_streams, current_streams_state)
        end)
    end
  end

  defp handle_async(
         :fetch_node_streams,
         # tu zwraca diffaa
         {:ok, streams_diff},
         %{
           assigns: %{
             streams_state: %AsyncResult{ok?: true, result: old_term_node}
           }
         } =
           socket
       ) do
    streams_state =
      case TermParser.update_by_diff(old_term_node, streams_diff) do
        {:ok, term_node} ->
          AsyncResult.ok(term_node)

        {:error, reason} ->
          AsyncResult.failed(socket.assigns.streams_state, reason)
      end

    socket
    |> assign(:streams_state, streams_state)
    |> halt()
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {initial_term_node, streams_diff,streams_state_list}},
         socket
       ) do
    # tu nie ma tego bo zwracam difffaf

    streams_state =
      case TermParser.update_by_diff(initial_term_node, streams_diff) do
        {:ok, term_node} ->
          AsyncResult.ok(term_node)

        {:error, reason} ->
          AsyncResult.failed(socket.assigns.streams_state, reason)
      end

    socket
    |> assign(:streams_state, streams_state)
    |> assign(:streams_state_list, streams_state_list)
    |> halt()
  end

  # defp handle_async(:fetch_node_streams, {:ok, {:ok, node_assigns}}, socket) do
  #   term_node = TermParser.term_to_display_tree(node_assigns)
  #   copy_string = TermParser.term_to_copy_string(node_assigns)

  #   socket
  #   |> assign(:node_assigns_info, AsyncResult.ok({node_assigns, term_node, copy_string}))
  #   |> halt()
  # end

  defp handle_async(:fetch_node_streams, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.stream_state, reason))
    |> halt()
  end

  defp handle_async(:fetch_node_streams, {:exit, reason}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.stream_state, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
