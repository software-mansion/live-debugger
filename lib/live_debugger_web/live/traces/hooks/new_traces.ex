defmodule LiveDebuggerWeb.Live.Traces.Hooks.NewTraces do
  @moduledoc """
  This hook is responsible for handling the new traces.
  It is used to handle the new traces when the user starts tracing.
  """

  use LiveDebuggerWeb, :hook

  alias LiveDebugger.Structs.TraceDisplay

  # These functions are using the `current_filters` assigns
  alias LiveDebuggerWeb.Live.Traces.Helpers

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t(), integer()) :: Phoenix.LiveView.Socket.t()
  def init(socket, live_stream_limit \\ 128) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(:lv_process)
    |> check_assigns!(:node_id)
    |> check_assigns!(:current_filters)
    |> check_assigns!(:traces_empty?)
    |> check_assigns!(:traces_continuation)
    |> check_assigns!(:existing_traces_status)
    |> check_assigns!(:trace_callback_running?)
    |> check_streams!(:existing_traces)
    |> put_private(:live_stream_limit, live_stream_limit)
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

    execution_time = Helpers.get_execution_times(socket)
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
