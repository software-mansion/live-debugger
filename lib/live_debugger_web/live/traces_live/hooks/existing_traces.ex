defmodule LiveDebuggerWeb.Live.TracesLive.Hooks.ExistingTraces do
  @moduledoc """
  This hook is responsible for fetching the existing traces and displaying them in the LiveView.
  It encapsulates logic for async fetching of traces.
  It attaches a hook to the `:existing_traces` stream to handle the async fetching.

  Required assigns (that are used somehow in the hook):
  - `:lv_process` - the LiveView process
  - `:current_filters` - the current filters
  - `:node_id` - the node ID
  - `:traces_empty?` - whether the existing traces are empty, possible values: `true`, `false`

  Required stream:
  - `:existing_traces` - the stream of existing traces.

  Assigns introduced by this hook (they can be used outside of the hook):
  - `:traces_continuation` - the continuation token for the existing traces, possible values: `nil`, `:end_of_table`, `ets_continuation()`
  - `:existing_traces_status` - the status of the existing traces, possible values: `:loading`, `:ok`, `:error`
  """

  require Logger

  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers
  import LiveDebuggerWeb.Live.TracesLive.Helpers

  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay

  def init_hook(socket, page_size) do
    socket
    |> check_assign(:lv_process)
    |> check_assign(:node_id)
    |> check_assign(:current_filters)
    |> check_assign(:traces_empty?)
    |> check_stream(:existing_traces)
    |> assign(:traces_continuation, nil)
    |> put_private(:page_size, page_size)
    |> attach_hook(:existing_traces, :handle_async, &handle_async/3)
  end

  @doc """
  It loads asynchronously the existing traces and assigns them to the `:existing_traces` stream.
  """
  @spec assign_async_existing_traces(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    page_size = socket.private.page_size
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: page_size,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  @doc """
  It loads asynchronously more existing traces and assigns them to the `:existing_traces` stream.
  """
  @spec assign_async_more_existing_traces(Phoenix.LiveView.Socket.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_async_more_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    cont = socket.assigns.traces_continuation
    page_size = socket.private.page_size
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)

    socket
    |> assign(:traces_continuation, :loading)
    |> start_async(:load_more_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: page_size,
        cont: cont,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  defp handle_async(:fetch_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(:existing_traces_status, :ok)
    |> assign(:traces_empty?, false)
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(:existing_traces_status, :ok)
    |> assign(:traces_continuation, :end_of_table)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    log_async_error("fetching existing traces", reason)

    socket
    |> assign(:existing_traces_status, :error)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(:traces_continuation, :end_of_table)
    |> halt()
  end

  # TODO: handle this case in a proper way
  defp handle_async(:load_more_existing_traces, {:exit, reason}, socket) do
    log_async_error("loading more existing traces", reason)

    socket
    |> halt()
  end

  defp handle_async(_, _, socket) do
    {:cont, socket}
  end

  defp get_active_functions(socket) do
    socket.assigns.current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.map(fn {function, _} -> function end)
  end

  defp get_execution_times(socket) do
    socket.assigns.current_filters.execution_time
    |> Enum.filter(fn {_, value} -> value != "" end)
    |> Enum.map(fn {filter, value} -> {filter, String.to_integer(value)} end)
  end

  defp log_async_error(operation, reason) do
    Logger.error(
      "LiveDebugger encountered unexpected error while #{operation}: #{inspect(reason)}"
    )
  end
end
