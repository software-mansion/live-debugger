defmodule LiveDebuggerWeb.Hooks.TracesLive.ExistingTraces do
  @moduledoc """
  Assigns introduced by this hook:
  - `:traces_continuation` - the continuation token for the existing traces, possible values: `nil`, `:end_of_table`, `ets_continuation()`
  - `:traces_empty?` - whether the existing traces are empty, possible values: `true`, `false`
  - `:existing_traces_status` - the status of the existing traces, possible values: `:loading`, `:ok`, `:error`

  Streams introduced by this hook:
  - `:existing_traces` - the stream of existing traces.
  """

  require Logger

  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers

  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay

  @page_size 25

  def init(socket) do
    socket
    |> assign(:traces_continuation, nil)
    |> assign(:traces_empty?, true)
    |> attach_hook(:fetch_existing_traces, :handle_async, &handle_async/3)
  end

  def assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)

    socket
    |> assign(:existing_traces_status, :loading)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: @page_size,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  def handle_async(:fetch_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(:existing_traces_status, :ok)
    |> assign(:traces_empty?, false)
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  def handle_async(:fetch_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(:existing_traces_status, :ok)
    |> assign(:traces_continuation, :end_of_table)
    |> halt()
  end

  def handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    log_async_error("fetching existing traces", reason)

    socket
    |> assign(:existing_traces_status, :error)
    |> halt()
  end

  def handle_async(_, _, socket) do
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

  Phoenix.Live
end
