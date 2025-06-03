defmodule LiveDebuggerWeb.Live.Traces.Components.LoadMoreButton do
  @moduledoc """
  This component is used to load more traces.
  It is used to load more traces when the user clicks the "Load more" button.
  It produces the `load-more` event that can be handled by the hook provided in the `init/1` function.
  """

  use LiveDebuggerWeb, :hook_component

  require Logger

  alias LiveDebugger.Services.TraceService
  alias LiveDebugger.Structs.TraceDisplay

  # These functions are using the `current_filters` assigns
  alias LiveDebuggerWeb.Live.Traces.Helpers

  @doc """
  Initializes the component by checking the assigns and streams and attaching the hook to the socket.
  The hook is used to handle the `load-more` event.
  """
  @spec init(Phoenix.LiveView.Socket.t(), integer()) :: Phoenix.LiveView.Socket.t()
  def init(socket, page_size \\ 25) do
    socket
    |> check_assigns!(:lv_process)
    |> check_assigns!(:node_id)
    |> check_assigns!(:traces_continuation)
    |> check_assigns!(:current_filters)
    |> check_streams!(:existing_traces)
    |> put_private(:page_size, page_size)
    |> attach_hook(:load_more_button, :handle_event, &handle_event/3)
    |> attach_hook(:load_more_button, :handle_async, &handle_async/3)
    |> register_hook(:load_more_button)
  end

  @doc """
  Renders the load more button.
  It is used to load more traces when the user clicks the "Load more" button.
  It produces the `load-more` event that can be handled by the hook provided in the `init/1` function.
  """
  attr(:traces_continuation, :any, required: true)

  def load_more_button(assigns) do
    ~H"""
    <div class="flex items-center justify-center mt-4">
      <.load_more_button_content traces_continuation={@traces_continuation} />
    </div>
    """
  end

  defp load_more_button_content(%{traces_continuation: nil} = assigns), do: ~H""
  defp load_more_button_content(%{traces_continuation: :end_of_table} = assigns), do: ~H""

  defp load_more_button_content(%{traces_continuation: :loading} = assigns) do
    ~H"""
    <.spinner size="sm" />
    """
  end

  defp load_more_button_content(%{traces_continuation: :error} = assigns) do
    ~H"""
    <.alert variant="danger" with_icon={true} heading="Error while loading more traces" class="w-full">
      Check logs for more details.
    </.alert>
    """
  end

  defp load_more_button_content(%{traces_continuation: cont} = assigns) when is_tuple(cont) do
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
    node_id = socket.assigns.node_id
    cont = socket.assigns.traces_continuation
    active_functions = Helpers.get_active_functions(socket)
    execution_times = Helpers.get_execution_times(socket)
    page_size = socket.private.page_size

    socket
    |> assign(:traces_continuation, :loading)
    |> start_async(:load_more_existing_traces, fn ->
      TraceService.existing_traces(pid,
        node_id: node_id,
        limit: page_size,
        cont: cont,
        functions: active_functions,
        execution_times: execution_times
      )
    end)
  end

  defp handle_async(:load_more_existing_traces, {:ok, {trace_list, cont}}, socket) do
    trace_list = Enum.map(trace_list, &TraceDisplay.from_trace/1)

    socket
    |> assign(:traces_continuation, cont)
    |> stream(:existing_traces, trace_list)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:ok, :end_of_table}, socket) do
    socket
    |> assign(:traces_continuation, :end_of_table)
    |> halt()
  end

  defp handle_async(:load_more_existing_traces, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while loading more existing traces: #{inspect(reason)}"
    )

    socket
    |> assign(:traces_continuation, :error)
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
