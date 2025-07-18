defmodule LiveDebuggerWeb.Live.Traces.Hooks.NewTraces do
  @moduledoc """
  This hook is responsible for handling the new traces.
  It is used to handle the new traces when the user starts tracing.
  """

  use LiveDebuggerWeb, :hook

  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay

  # This function is using the `current_filters` assigns
  import LiveDebuggerWeb.Live.Traces.Helpers, only: [get_execution_times: 1]

  @required_assigns [
    :lv_process,
    :current_filters,
    :traces_empty?,
    :traces_continuation,
    :existing_traces_status,
    :trace_callback_running?
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t(), integer()) :: Phoenix.LiveView.Socket.t()
  def init(socket, live_stream_limit \\ 128) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> put_private(:live_stream_limit, live_stream_limit)
    |> attach_hook(:new_traces, :handle_info, &handle_info/2)
    |> register_hook(:new_traces)
  end

  defp handle_info({:new_trace, trace}, socket) do
    socket =
      if TraceService.trace_contains?(trace, socket.assigns.trace_search_query) do
        live_stream_limit = socket.private.live_stream_limit

        trace_display = TraceDisplay.from_trace(trace, true)

        socket
        |> stream_insert(:existing_traces, trace_display, at: 0, limit: live_stream_limit)
        |> assign(traces_empty?: false)
      else
        socket
      end

    socket
    |> assign(trace_callback_running?: true)
    |> halt()
  end

  defp handle_info({:updated_trace, trace}, socket) do
    search_match? = TraceService.trace_contains?(trace, socket.assigns.trace_search_query)

    socket
    |> maybe_update_stream(trace, search_match?)
    |> assign(trace_callback_running?: false)
    |> push_event("stop-timer", %{})
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  @spec maybe_update_stream(
          Phoenix.LiveView.Socket.t(),
          LiveDebugger.Structs.TraceDisplay.t(),
          boolean()
        ) :: Phoenix.LiveView.Socket.t()
  defp maybe_update_stream(socket, _, false = _search_match?), do: socket

  defp maybe_update_stream(socket, trace, true = _search_match) do
    trace_display = TraceDisplay.from_trace(trace, true)
    live_stream_limit = socket.private.live_stream_limit

    execution_time = get_execution_times(socket)
    min_time = Map.get(execution_time, "exec_time_min", 0)
    max_time = Map.get(execution_time, "exec_time_max", :infinity)

    if trace.execution_time >= min_time and trace.execution_time <= max_time do
      socket
      |> stream_insert(:existing_traces, trace_display, at: 0, limit: live_stream_limit)
    else
      socket
      |> stream_delete(:existing_traces, trace_display)
    end
  end
end
