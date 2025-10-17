defmodule LiveDebugger.App.Debugger.NodeState.Web.LiveComponents.AssignsSize do
  @moduledoc """
  Live component to display the size of the assigns.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.Utils.Memory
  alias Phoenix.LiveView.AsyncResult

  @assigns_size_events [:assigns_size_1, :assigns_size_2]

  @impl true
  def mount(socket) do
    socket
    |> assign(:assigns_sizes, AsyncResult.loading())
    |> ok()
  end

  @impl true
  def update(%{assigns: assigns, id: id}, socket) do
    socket
    |> assign(:id, id)
    |> assign(assigns: assigns)
    |> assign_size_async(assigns)
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-xs text-secondary-text flex gap-1">
      <span>Assigns size: </span>
      <.async_result :let={assigns_sizes} assign={@assigns_sizes}>
        <.tooltip
          id={@id <> "-tooltip-heap"}
          content="Memory used by assigns inside the LiveView process."
          class="truncate"
          position="top-center"
        >
          <span><%= assigns_sizes.heap_size %> heap</span>
        </.tooltip>
        <span> / </span>
        <.tooltip
          id={@id <> "-tooltip-serialized"}
          content="Size of assigns when encoded for transfer."
          class="truncate"
          position="top-center"
        >
          <span><%= assigns_sizes.serialized_size %> serialized</span>
        </.tooltip>
        <:loading>
          <.spinner size="sm" />
        </:loading>
        <:failed>
          <span class="text-red-700"> error </span>
        </:failed>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_async(ev, {:ok, assigns_sizes}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.ok(assigns_sizes))
    |> noreply()
  end

  def handle_async(ev, {:exit, {reason, _}}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.failed(%AsyncResult{}, reason))
    |> noreply()
  end

  # If one async task is already running, we start the second async task
  # If both async tasks are running, we start the second async task
  defp assign_size_async(%{private: %{live_async: %{assigns_size_1: _}}} = socket, assigns) do
    start_async(socket, :assigns_size_2, fn -> calculate_assigns_size(assigns) end)
  end

  # If assigns are not calculated, we start the first async task
  defp assign_size_async(socket, assigns) do
    start_async(socket, :assigns_size_1, fn -> calculate_assigns_size(assigns) end)
  end

  defp calculate_assigns_size(assigns) do
    %{heap_size: assigns_heap_size(assigns), serialized_size: assigns_serialized_size(assigns)}
  end

  defp assigns_heap_size(assigns) do
    assigns |> Memory.term_heap_size() |> Memory.bytes_to_pretty_string()
  end

  defp assigns_serialized_size(assigns) do
    assigns |> Memory.serialized_term_size() |> Memory.bytes_to_pretty_string()
  end
end
