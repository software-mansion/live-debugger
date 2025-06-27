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
    dbg(socket.assigns.current_filters)

    dbg(trace)

    socket
    |> halt()
  end

  # defp handle_info({:updated_trace, trace}, socket) do
  #   socket
  #   |> stream_insert(:existing_traces, trace_display, at: 0, limit: live_stream_limit)
  #   |> assign(traces_empty?: false)
  #   |> assign(trace_callback_running?: true)
  #   |> halt()
  # end

  defp handle_info(_, socket), do: {:cont, socket}
end
