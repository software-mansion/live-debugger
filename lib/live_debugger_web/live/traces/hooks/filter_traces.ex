defmodule LiveDebuggerWeb.Live.Traces.Hooks.FilterTraces do
  @moduledoc """
  This hook is responsible for filtering the traces.
  """

  use LiveDebuggerWeb, :hook

  @required_assigns [
    :current_filters
  ]

  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filter_traces, :handle_info, &handle_info/2)
    |> register_hook(:filter_traces)
  end

  defp handle_info({:new_trace, trace}, socket) do
    if matches_function_filter?(trace, socket.assigns.current_filters) do
      {:cont, socket}
    else
      {:halt, socket}
    end
  end

  defp handle_info({:updated_trace, trace}, socket) do
    if matches_function_filter?(trace, socket.assigns.current_filters) do
      {:cont, socket}
    else
      {:halt, socket}
    end
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp matches_function_filter?(trace, current_filters) do
    current_filters.functions["#{trace.function}/#{trace.arity}"]
  end
end
