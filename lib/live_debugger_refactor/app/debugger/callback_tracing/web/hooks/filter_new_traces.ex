defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Hooks.FilterNewTraces do
  @moduledoc """
  This hook is responsible for filtering the traces.
  """

  use LiveDebuggerRefactor.App.Web, :hook

  alias LiveDebuggerRefactor.API.TracesStorage

  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceErrored

  @required_assigns [
    :current_filters
  ]

  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filter_new_traces, :handle_info, &handle_info/2)
    |> register_hook(:filter_new_traces)
  end

  defp handle_info(%TraceCalled{} = trace_called, socket) do
    filter_trace_event(socket, trace_called)
  end

  defp handle_info(%TraceReturned{} = trace_returned, socket) do
    filter_trace_event(socket, trace_returned)
  end

  defp handle_info(%TraceErrored{} = trace_errored, socket) do
    filter_trace_event(socket, trace_errored)
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp filter_trace_event(socket, trace_event) do
    with true <- matches_node_id?(socket, trace_event),
         true <- matches_function_filter?(socket, trace_event),
         true <- matches_search_query?(socket, trace_event) do
      {:cont, socket}
    else
      _ -> {:halt, socket}
    end
  end

  defp matches_node_id?(socket, trace_event) do
    case socket.assigns[:node_id] do
      nil -> true
      pid when is_pid(pid) -> pid == trace_event.pid
      %Phoenix.LiveComponent.CID{} = cid -> cid == trace_event.cid
    end
  end

  defp matches_function_filter?(socket, %{function: function, arity: arity}) do
    socket.assigns.current_filters.functions["#{function}/#{arity}"]
  end

  defp matches_search_query?(socket, %{ets_ref: ets_ref, trace_id: trace_id}) do
    case Map.get(socket.assigns, :trace_search_query, "") do
      "" ->
        true

      search ->
        TracesStorage.get_by_id!(ets_ref, trace_id)
        |> inspect()
        |> String.downcase()
        |> String.contains?(search)
    end
  end
end
