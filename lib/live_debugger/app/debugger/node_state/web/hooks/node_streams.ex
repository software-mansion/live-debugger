defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.NodeStreams do
  @moduledoc """
  This hook is responsible for fetching streams of a specific node.
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
    |> assign(:stream_names, AsyncResult.loading())
    |> assign(:streams_tree, AsyncResult.loading())
    |> assign_async_streams_tree()
  end

  @doc """
  Assigns the async node streams to the socket.
  """
  def assign_async_streams_tree(%{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket)
      when not is_nil(node_id) do
    socket
    |> start_async(:fetch_node_streams, fn ->
      NodeStateQueries.fetch_node_streams(pid)
    end)
  end

  def assign_async_streams_tree(socket) do
    assign(socket, :stream_tree, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  def assign_async_streams_tree(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        updated_streams
      )
      when not is_nil(node_id) do
    case Map.get(socket.assigns, :stream_index_map, nil) do
      nil ->
        assign_async_streams_tree(socket)

      current_stream_index_map ->
        # socket
        # |> start_async(:fetch_node_streams, fn ->
        #   NodeStateQueries.update_node_streams(pid, updated_streams, current_stream_index_map)
        # end)
        assign_async_streams_tree(socket)
    end
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {fun_list, stream_names}},
         socket
       ) do
    dbg({fun_list, stream_names})

    socket
    |> assign(:stream_tree, [])
    |> assign_stream_names(stream_names)
    |> apply_stream_transformations(fun_list)
    |> assign(:stream_names, AsyncResult.ok(stream_names))
    |> halt()
  end

  defp assign_stream_names(socket, stream_names) do
    Enum.reduce(stream_names, socket, fn stream_name, acc ->
      stream(acc, stream_name, [])
    end)
  end

  defp apply_stream_transformations(socket, fun_list) do
    Enum.reduce(fun_list, socket, fn fun, acc ->
      dbg(:erlang.fun_info(fun))
      fun.(acc)
    end)
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {streams_diff, updated_stream_index_map}},
         %{
           assigns: %{
             streams_tree: %AsyncResult{ok?: true, result: previous_streams_tree}
           }
         } = socket
       ) do
    dbg({streams_diff, updated_stream_index_map})

    streams_tree =
      case TermParser.update_by_diff(previous_streams_tree, streams_diff) do
        {:ok, new_stream_tree} ->
          AsyncResult.ok(new_stream_tree)

        {:error, reason} ->
          AsyncResult.failed(socket.assigns.streams_tree, reason)
      end

    # dbg(streams_tree)

    socket
    |> assign(:streams_tree, streams_tree)
    |> assign(:stream_index_map, updated_stream_index_map)
    |> halt()
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {initial_streams_tree, streams_diff, stream_index_map}},
         socket
       ) do
    streams_tree =
      case TermParser.update_by_diff(initial_streams_tree, streams_diff) do
        {:ok, new_streams_tree} ->
          AsyncResult.ok(new_streams_tree)

        {:error, reason} ->
          AsyncResult.failed(socket.assigns.streams_tree, reason)
      end

    socket
    |> assign(:streams_tree, streams_tree)
    |> assign(:stream_index_map, stream_index_map)
    # |> assign_stream_names(stream_names)
    |> halt()
  end

  defp handle_async(:fetch_node_streams, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:streams_tree, AsyncResult.failed(socket.assigns.streams_tree, reason))
    |> halt()
  end

  defp handle_async(:fetch_node_streams, {:exit, reason}, socket) do
    socket
    |> assign(:streams_tree, AsyncResult.failed(socket.assigns.streams_tree, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
