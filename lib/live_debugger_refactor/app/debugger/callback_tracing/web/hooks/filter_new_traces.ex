defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Hooks.FilterNewTraces do
  @moduledoc """
  This hook is responsible for filtering the traces.
  """

  use LiveDebuggerRefactor.App.Web, :hook

  alias LiveDebuggerRefactor.API.TracesStorage

  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned

  @required_assigns [
    :current_filters
  ]

  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filter_traces, :handle_info, &handle_info/2)
    |> register_hook(:filter_traces)
  end

  defp handle_info(%TraceCalled{} = trace_called, socket) do
    with true <- matches_function_filter?(socket, trace_called),
         true <- matches_search_query?(socket, trace_called) do
      dbg(trace_called)
      {:cont, socket}
    else
      _ -> {:halt, socket}
    end
  end

  defp handle_info(%TraceReturned{} = trace_returned, socket) do
    with true <- matches_function_filter?(socket, trace_returned),
         true <- matches_search_query?(socket, trace_returned) do
      dbg(trace_returned)
      {:cont, socket}
    else
      _ -> {:halt, socket}
    end
  end

  defp handle_info(_, socket), do: {:cont, socket}

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
