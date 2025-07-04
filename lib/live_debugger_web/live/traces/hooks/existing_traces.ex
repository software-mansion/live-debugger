defmodule LiveDebuggerWeb.Live.Traces.Hooks.ExistingTraces do
  @moduledoc """
  This hook is responsible for fetching the existing traces.
  It is used to fetch the existing traces when the user clicks the "Load more" button
  """

  use LiveDebuggerWeb, :hook

  require Logger

  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Services.TraceService

  # These functions are using the `current_filters` assigns
  import LiveDebuggerWeb.Live.Traces.Helpers,
    only: [get_active_functions: 1, get_execution_times: 1]

  @required_assigns [
    :lv_process,
    :current_filters,
    :traces_empty?,
    :traces_continuation,
    :existing_traces_status
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t(), integer()) :: Phoenix.LiveView.Socket.t()
  def init(socket, page_size \\ 25) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> put_private(:page_size, page_size)
    |> attach_hook(:existing_traces, :handle_async, &handle_async/3)
    |> register_hook(:existing_traces)
    |> assign_async_existing_traces()
  end

  @doc """
  Loads the existing traces asynchronously and assigns them to the socket.
  """
  @spec assign_async_existing_traces(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = Map.get(socket.assigns, :node_id)
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)
    page_size = socket.private.page_size
    search_query = socket.assigns.trace_search_query

    opts =
      [
        limit: page_size,
        functions: active_functions,
        execution_times: execution_times,
        node_id: node_id,
        search_query: search_query
      ]

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(pid, opts)
    end)
  end

  defp handle_async(:fetch_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(existing_traces_status: :ok)
    |> assign(:traces_empty?, false)
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(existing_traces_status: :ok)
    |> assign(traces_continuation: :end_of_table)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(existing_traces_status: :error)
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
