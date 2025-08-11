defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Hooks.DisplayNewTraces do
  @moduledoc """
  This hook is responsible for displaying new traces.
  It is used to display new traces when the user starts tracing.
  """

  use LiveDebuggerRefactor.App.Web, :hook

  alias LiveDebuggerRefactor.Structs.Trace
  alias LiveDebuggerRefactor.API.TracesStorage
  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers
  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.Structs.TraceDisplay

  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceErrored

  @debounce_timeout 1

  @required_assigns [
    :current_filters,
    :traces_empty?
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns, other hooks and streams.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:tracing_fuse)
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> check_private!(:live_stream_limit)
    |> put_private(:canceled, false)
    |> attach_hook(:display_new_traces, :handle_info, &handle_info/2)
    |> register_hook(:display_new_traces)
  end

  defp handle_info(%TraceCalled{} = trace_called, socket) do
    debounce_trace_event(trace_called)

    socket
    |> put_private(:canceled, false)
    |> halt()
  end

  defp handle_info(%TraceReturned{trace_id: trace_id, ets_ref: table}, socket) do
    trace = TracesStorage.get_by_id!(table, trace_id)

    socket
    |> stream_update_trace(trace)
    |> push_event("stop-timer", %{})
    |> halt()
  end

  defp handle_info(%TraceErrored{trace_id: trace_id, ets_ref: table}, socket) do
    trace = TracesStorage.get_by_id!(table, trace_id)

    socket
    |> stream_update_trace(trace)
    |> push_event("stop-timer", %{})
    |> halt()
  end

  defp handle_info({:debounce, _}, socket) when socket.private.canceled do
    {:halt, socket}
  end

  defp handle_info({:debounce, %TraceCalled{trace_id: trace_id, ets_ref: table}}, socket) do
    trace = TracesStorage.get_by_id!(table, trace_id)

    socket
    |> stream_insert_trace(trace)
    |> assign(traces_empty?: false)
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp stream_insert_trace(socket, trace) do
    stream_insert(
      socket,
      :existing_traces,
      TraceDisplay.from_trace(trace, true),
      at: 0,
      limit: socket.private.live_stream_limit
    )
  end

  defp stream_update_trace(socket, trace) do
    trace_display = TraceDisplay.from_trace(trace, true)

    if matches_execution_time_filter?(socket, trace) do
      stream_insert(
        socket,
        :existing_traces,
        trace_display,
        at: 0,
        limit: socket.private.live_stream_limit
      )
    else
      socket
      |> put_private(:canceled, true)
      |> stream_delete(:existing_traces, trace_display)
    end
  end

  defp matches_execution_time_filter?(socket, %Trace{execution_time: execution_time}) do
    execution_time_limits = FiltersHelpers.get_execution_times(socket.assigns.current_filters)

    min_time = Map.get(execution_time_limits, "exec_time_min", 0)
    max_time = Map.get(execution_time_limits, "exec_time_max", :infinity)

    execution_time >= min_time and execution_time <= max_time
  end

  defp debounce_trace_event(event) do
    Process.send_after(self(), {:debounce, event}, @debounce_timeout)
  end
end
