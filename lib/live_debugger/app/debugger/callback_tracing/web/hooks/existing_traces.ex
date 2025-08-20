defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks.ExistingTraces do
  @moduledoc """
  This hook is responsible for fetching the existing traces.
  """

  use LiveDebugger.App.Web, :hook

  require Logger

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  @required_assigns [
    :lv_process,
    :current_filters,
    :traces_empty?,
    :traces_continuation,
    :existing_traces_status
  ]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> check_private!(:page_size)
    |> attach_hook(:existing_traces, :handle_async, &handle_async/3)
    |> register_hook(:existing_traces)
    |> assign_async_existing_traces()
  end

  @doc """
  Loads the existing traces asynchronously and assigns them to the socket.
  """
  @spec assign_async_existing_traces(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def assign_async_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid

    opts =
      [
        limit: socket.private.page_size,
        functions: FiltersHelpers.get_active_functions(socket.assigns.current_filters),
        execution_times: FiltersHelpers.get_execution_times(socket.assigns.current_filters),
        node_id: Map.get(socket.assigns, :node_id),
        search_phrase: Map.get(socket.assigns, :trace_search_phrase, "")
      ]

    socket
    |> assign(:traces_empty?, true)
    |> stream(:existing_traces, [], reset: true)
    |> start_async(:fetch_existing_traces, fn -> TracesStorage.get!(pid, opts) end)
  end

  defp handle_async(:fetch_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(
      existing_traces_status: :ok,
      traces_empty?: false,
      traces_continuation: cont
    )
    |> stream(:existing_traces, trace_list, reset: true)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(
      existing_traces_status: :ok,
      traces_continuation: :end_of_table
    )
    |> stream(:existing_traces, [], reset: true)
    |> halt()
  end

  defp handle_async(:fetch_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(existing_traces_status: :error)
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
