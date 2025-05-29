defmodule LiveDebuggerWeb.Hooks.TracesLive.IncomingTraces do
  @moduledoc """
  Has to be declared before TracingHelper hook.

  Required assigns:
  - `:current_filters` - the current filters
  - `:traces_empty?` - whether the existing traces are empty, possible values: `true`, `false`
  - `:trace_callback_running?` - whether the trace callback is running

  Assigns introduced by this hook:


  Required stream:
  - `:existing_traces` - the stream of existing traces.
  """

  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers

  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebuggerWeb.Helpers.TracingHelper

  @live_stream_limit 128

  def init_hook(socket) do
    socket
    |> check_assign(:current_filters)
    |> check_assign(:traces_empty?)
    |> check_stream(:existing_traces)
    |> check_assign(:trace_callback_running?)
    |> attach_hook(:incoming_traces, :handle_info, &handle_info/2)
  end

  def handle_info({:new_trace, trace}, socket) do
    trace_display = TraceDisplay.from_trace(trace, true)

    socket
    |> stream_insert(:existing_traces, trace_display, at: 0, limit: @live_stream_limit)
    |> assign(traces_empty?: false)
    |> assign(trace_callback_running?: true)
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

  defp check_assign(socket, assign_name) do
    if Map.has_key?(socket.assigns, assign_name) do
      socket
    else
      raise "Assign #{assign_name} is required by this hook: #{__MODULE__}"
    end
  end

  defp check_stream(socket, stream_name) do
    if Map.has_key?(socket.assigns.streams, stream_name) do
      socket
    else
      raise "Stream #{stream_name} is required by this hook: #{__MODULE__}"
    end
  end
end
