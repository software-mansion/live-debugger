defmodule LiveDebuggerWeb.Hooks.Traces.ExistingTraces do
  require Logger

  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers
  import LiveDebuggerWeb.Helpers.TracesLiveHelper

  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Services.TraceService

  def attach_hook(socket, page_size \\ 25) do
    socket
    |> check_hook!(:tracing_fuse)
    |> put_private(:page_size, page_size)
    |> attach_hook(:existing_traces, :handle_async, &handle_async/3)
    |> register_hook(:existing_traces)
    |> assign_async_existing_traces()
  end

  def assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid
    node_id = socket.assigns.node_id
    active_functions = get_active_functions(socket)
    execution_times = get_execution_times(socket)
    page_size = socket.private.page_size

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
