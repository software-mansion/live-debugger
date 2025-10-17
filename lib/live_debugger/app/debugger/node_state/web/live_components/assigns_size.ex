defmodule LiveDebugger.App.Debugger.NodeState.Web.LiveComponents.AssignsSize do
  @moduledoc """
  Live component to display the size of the assigns.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.Utils.Memory

  @impl true
  def update(%{assigns: assigns, id: id}, socket) do
    socket
    |> assign(assigns: assigns)
    |> assign(:id, id)
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="text-xs text-secondary-text flex gap-1">
      <span>Assigns size: </span>
      <.tooltip
        id={@id <> "-tooltip-heap"}
        content="Memory used by assigns inside the LiveView process."
        class="truncate"
        position="top-center"
      >
        <span><%= assigns_heap_size(assigns) %> heap</span>
      </.tooltip>
      <span> / </span>
      <.tooltip
        id={@id <> "-tooltip-serialized"}
        content="Size of assigns when encoded for transfer."
        class="truncate"
        position="top-center"
      >
        <%= assigns_serialized_size(@assigns) %> serialized
      </.tooltip>
    </div>
    """
  end

  defp assigns_heap_size(assigns) do
    assigns |> Memory.term_heap_size() |> Memory.bytes_to_pretty_string()
  end

  defp assigns_serialized_size(assigns) do
    assigns |> Memory.serialized_term_size() |> Memory.bytes_to_pretty_string()
  end
end
