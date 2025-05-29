defmodule LiveDebuggerWeb.Hooks.TracesLive.IncomingTraces do
  @moduledoc """
  Required assigns:

  Assigns introduced by this hook:

  """

  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers

  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebuggerWeb.Hooks.Flash
  alias LiveDebuggerWeb.Helpers.TracingHelper
  alias LiveDebugger.Utils.Parsers

  @live_stream_limit 128

  def init_hook(socket) do
    socket
    |> attach_hook(:incoming_traces, :handle_info, &handle_info/2)
  end

  def handle_info({:new_trace, trace}, socket) do
    socket
    |> TracingHelper.check_fuse()
    |> case do
      {:ok, socket} ->
        trace_display = TraceDisplay.from_trace(trace, true)

        socket
        |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
        |> assign(traces_empty?: false)
        |> assign(trace_callback_running?: true)

      {:stopped, socket} ->
        limit = TracingHelper.trace_limit_per_period()
        period = TracingHelper.time_period() |> Parsers.parse_elapsed_time()

        socket.assigns.root_pid
        |> Flash.push_flash(
          socket,
          "Callback tracer stopped: Too many callbacks in a short time. Current limit is #{limit} callbacks in #{period}."
        )

      {_, socket} ->
        socket
    end
    |> halt()
  end

  def handle_info({:updated_trace, trace}, socket) when socket.assigns.trace_callback_running? do
    trace_display = TraceDisplay.from_trace(trace, true)

    execution_time = get_execution_times(socket)
    min_time = Keyword.get(execution_time, :exec_time_min, 0)
    max_time = Keyword.get(execution_time, :exec_time_max, :infinity)

    if trace.execution_time >= min_time and trace.execution_time <= max_time do
      socket
      |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
    else
      socket
      |> stream_delete(:existing_traces, trace_display)
    end
    |> assign(trace_callback_running?: false)
    |> TracingHelper.maybe_disable_tracing_after_update()
    |> push_event("stop-timer", %{})
    |> halt()
  end

  def handle_info({:updated_trace, _trace}, socket) do
    {:halt, socket}
  end

  def handle_info(_, socket) do
    {:cont, socket}
  end

  defp get_execution_times(socket) do
    socket.assigns.current_filters.execution_time
    |> Enum.filter(fn {_, value} -> value != "" end)
    |> Enum.map(fn {filter, value} -> {filter, String.to_integer(value)} end)
  end
end
