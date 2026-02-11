defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks.FilterNewTraces do
  @moduledoc """
  This hook is responsible for filtering the traces.
  """

  use LiveDebugger.App.Web, :hook

  import LiveDebugger.App.Web.Hooks.Flash, only: [push_flash: 4]

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebugger.Services.CallbackTracer.Events.TraceErrored
  alias LiveDebugger.Services.CallbackTracer.Events.DiffTraceCreated
  alias LiveDebugger.Services.CallbackTracer.Events.TraceExceptionUpdated
  alias LiveDebugger.App.Web.Helpers.Routes
  alias LiveDebugger.App.Web.Hooks.Flash.ExceptionFlashData

  @required_assigns [
    :current_filters,
    :node_id,
    :parent_pid
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns, other hooks and streams.
  """
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

  defp handle_info(%TraceExceptionUpdated{} = trace_exception, socket) do
    filter_trace_event(socket, trace_exception)
  end

  defp handle_info(%DiffTraceCreated{}, socket) do
    if diff_traces_filter_enabled?(socket) do
      {:cont, socket}
    else
      {:halt, socket}
    end
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp filter_trace_event(socket, trace_event) do
    with true <- matches_node_id?(socket, trace_event),
         true <- matches_function_filter?(socket, trace_event),
         true <- matches_search_phrase?(socket, trace_event) do
      {:cont, socket}
    else
      _ ->
        socket =
          case trace_event do
            %TraceExceptionUpdated{} = trace_exception ->
              push_exception_flash(socket, trace_exception)

            _ ->
              socket
          end

        {:halt, socket}
    end
  end

  defp matches_node_id?(socket, trace_event) do
    case socket.assigns.node_id do
      nil ->
        true

      pid when is_pid(pid) ->
        pid == trace_event.pid && trace_event.cid == nil

      %Phoenix.LiveComponent.CID{} = cid ->
        cid == trace_event.cid
    end
  end

  defp matches_function_filter?(socket, %{function: function, arity: arity}) do
    socket.assigns.current_filters.functions["#{function}/#{arity}"]
  end

  defp matches_search_phrase?(socket, %{ets_ref: ets_ref, trace_id: trace_id}) do
    case Map.get(socket.assigns, :trace_search_phrase, "") do
      "" ->
        true

      search ->
        TracesStorage.get_by_id!(ets_ref, trace_id)
        |> Map.get(:args)
        |> inspect(limit: :infinity, structs: false)
        |> String.downcase()
        |> String.contains?(String.downcase(search))
    end
  end

  defp diff_traces_filter_enabled?(socket) do
    socket.assigns.current_filters.other_filters["trace_diffs"]
  end

  defp push_exception_flash(socket, trace_exception) do
    flash_data = %ExceptionFlashData{
      text: if(trace_exception.cid, do: "Live Component crashed.", else: "Live View crashed."),
      module: trace_exception.module |> to_string() |> String.replace_prefix("Elixir.", ""),
      label: "Open in Node Inspector",
      url: Routes.debugger_node_inspector(trace_exception.pid, cid: trace_exception.cid)
    }

    push_flash(
      socket,
      :error,
      flash_data,
      socket.assigns.parent_pid
    )
  end
end
