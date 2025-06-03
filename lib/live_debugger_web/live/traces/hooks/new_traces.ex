defmodule LiveDebuggerWeb.Live.Traces.Hooks.NewTraces do
  import Phoenix.LiveView
  import Phoenix.Component

  import LiveDebuggerWeb.Helpers
  import LiveDebuggerWeb.Live.Traces.Helpers

  alias LiveDebugger.Structs.TraceDisplay

  def attach_hook(socket, live_stream_limit \\ 128) do
    socket
    |> check_hook!(:tracing_fuse)
    |> put_private(:live_stream_limit, live_stream_limit)
    |> check_assigns!(:trace_callback_running?)
    |> attach_hook(:new_traces, :handle_info, &handle_info/2)
    |> register_hook(:new_traces)
  end

  defp handle_info({:new_trace, trace}, socket) do
    live_stream_limit = socket.private.live_stream_limit

    trace_display = TraceDisplay.from_trace(trace, true)

    socket
    |> stream_insert(:existing_traces, trace_display, at: 0, limit: live_stream_limit)
    |> assign(traces_empty?: false)
    |> assign(trace_callback_running?: true)
    |> halt()
  end

  defp handle_info({:updated_trace, trace}, socket) do
    live_stream_limit = socket.private.live_stream_limit
    trace_display = TraceDisplay.from_trace(trace, true)

    execution_time = get_execution_times(socket)
    min_time = Keyword.get(execution_time, :exec_time_min, 0)
    max_time = Keyword.get(execution_time, :exec_time_max, :infinity)

    if trace.execution_time >= min_time and trace.execution_time <= max_time do
      socket
      |> stream_insert(:existing_traces, trace_display, at: 0, limit: live_stream_limit)
    else
      socket
      |> stream_delete(:existing_traces, trace_display)
    end
    |> assign(trace_callback_running?: false)
    |> push_event("stop-timer", %{})
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
