defmodule LiveDebugger.App.Debugger.Streams.Web.Hooks.Streams do
  @moduledoc """
  This hook is responsible for fetching streams of a specific node.
  """

  use LiveDebugger.App.Web, :hook

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.Streams.Queries, as: StreamsQueries

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
    |> assign_async_streams()
  end

  @doc """
  Assigns the async node streams to the socket.
  """
  def assign_async_streams(%{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket)
      when not is_nil(node_id) do
    socket
    |> start_async(:fetch_node_streams, fn ->
      StreamsQueries.fetch_node_streams(pid)
    end)
  end

  def assign_async_streams(socket) do
    assign(socket, :stream_names, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  def assign_async_streams(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        updated_streams,
        dom_id_fun
      )
      when not is_nil(node_id) do
    case Map.get(socket.assigns, :stream_names, nil) do
      nil ->
        assign_async_streams(socket)

      _ ->
        socket
        |> start_async(:fetch_node_streams, fn ->
          StreamsQueries.update_node_streams(pid, updated_streams, dom_id_fun)
        end)
    end
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {fun_list, config_list, stream_name}},
         %{
           assigns: %{
             stream_names: %AsyncResult{ok?: true, result: current_stream_names}
           }
         } = socket
       ) do
    socket
    |> apply_stream_transformations(config_list)
    |> maybe_assign_stream_name(stream_name, current_stream_names)
    |> apply_stream_transformations(fun_list)
    |> assign(
      :stream_names,
      AsyncResult.ok((current_stream_names ++ [stream_name]) |> Enum.uniq())
    )
    |> halt()
  end

  defp handle_async(
         :fetch_node_streams,
         {:ok, {fun_list, config_list, stream_names}},
         socket
       ) do
    socket
    |> apply_stream_transformations(config_list)
    |> assign_stream_names(stream_names)
    |> apply_stream_transformations(fun_list)
    |> assign(:stream_names, AsyncResult.ok(stream_names))
    |> halt()
  end

  defp handle_async(:fetch_node_streams, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:stream_names, AsyncResult.failed(socket.assigns.stream_names, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp maybe_assign_stream_name(socket, stream_name, current_stream_names) do
    if stream_name in current_stream_names do
      socket
    else
      stream(socket, stream_name, [])
    end
  end

  defp assign_stream_names(socket, stream_names) do
    Enum.reduce(stream_names, socket, fn stream_name, acc ->
      stream(acc, stream_name, [])
    end)
  end

  defp apply_stream_transformations(socket, fun_list) do
    Enum.reduce(fun_list, socket, fn fun, acc ->
      fun.(acc)
    end)
  end
end
