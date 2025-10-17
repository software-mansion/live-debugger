defmodule LiveDebugger.App.Debugger.NodeState.Web.LiveComponents.AssignsSize do
  @moduledoc """
  Live component to display the size of the assigns.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.Utils.Memory
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def update(%{assigns: assigns, id: id}, socket) do
    socket
    |> assign(assigns: assigns)
    |> assign(:assigns_sizes, AsyncResult.loading())
    |> start_async(:assigns_size, fn -> calculate_assigns_size(assigns) end)
    |> assign(:id, id)
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
  def handle_async(:assigns_size, {:ok, assigns_sizes}, socket) do
    socket
    |> assign(:assigns_sizes, AsyncResult.ok(assigns_sizes))
    |> noreply()
  end

  def handle_async(:assigns_size, {:exit, {reason, _}}, socket) do
    socket
    |> assign(:assigns_sizes, AsyncResult.failed(%AsyncResult{}, reason))
    |> noreply()
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
