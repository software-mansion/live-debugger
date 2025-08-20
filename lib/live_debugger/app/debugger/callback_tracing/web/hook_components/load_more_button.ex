defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.LoadMoreButton do
  @moduledoc """
  This component is used to load more traces.
  It uses `trace_continuation` to determine if there are more traces to load.
  It produces `load-more` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  require Logger

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  @required_assigns [:lv_process, :traces_continuation, :current_filters, :node_id]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> check_private!(:page_size)
    |> attach_hook(:load_more_button, :handle_event, &handle_event/3)
    |> attach_hook(:load_more_button, :handle_async, &handle_async/3)
    |> register_hook(:load_more_button)
  end

  attr(:traces_continuation, :any, required: true)

  @impl true
  def render(%{traces_continuation: nil} = assigns), do: ~H""
  def render(%{traces_continuation: :end_of_table} = assigns), do: ~H""

  def render(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <.content traces_continuation={@traces_continuation} />
    </div>
    """
  end

  defp content(%{traces_continuation: :loading} = assigns) do
    ~H"""
    <.spinner size="sm" />
    """
  end

  defp content(%{traces_continuation: :error} = assigns) do
    ~H"""
    <.alert with_icon={true} heading="Error while loading more traces" class="w-full">
      Check logs for more details.
    </.alert>
    """
  end

  defp content(%{traces_continuation: cont} = assigns) when is_tuple(cont) do
    ~H"""
    <.button phx-click="load-more" class="w-4" variant="secondary">
      Load more
    </.button>
    """
  end

  defp handle_event("load-more", _, socket) do
    socket
    |> load_more_existing_traces()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp load_more_existing_traces(socket) do
    pid = socket.assigns.lv_process.pid

    opts =
      [
        limit: socket.private.page_size,
        functions: FiltersHelpers.get_active_functions(socket.assigns.current_filters),
        execution_times: FiltersHelpers.get_execution_times(socket.assigns.current_filters),
        node_id: socket.assigns.node_id,
        search_phrase: Map.get(socket.assigns, :trace_search_phrase, ""),
        cont: socket.assigns.traces_continuation
      ]

    socket
    |> assign(traces_continuation: :loading)
    |> start_async(:load_more_existing_traces, fn -> TracesStorage.get!(pid, opts) end)
  end

  defp handle_async(:load_more_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(traces_continuation: cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(traces_continuation: :end_of_table)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while loading more existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(traces_continuation: :error)
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
