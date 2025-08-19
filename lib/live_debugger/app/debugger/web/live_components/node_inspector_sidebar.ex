defmodule LiveDebugger.App.Debugger.Web.LiveComponents.NodeInspectorSidebar do
  @moduledoc """
  Sidebar for the node inspector.
  It can be opened and closed by sending "open-sidebar" and "close-sidebar" events.
  It has basic information about the node.
  """

  use LiveDebugger.App.Web, :live_component

  @impl true
  def mount(socket) do
    socket
    |> assign(:hidden?, true)
    |> ok()
  end

  @impl true
  def update(%{hidden?: hidden?}, socket) do
    socket
    |> assign(:hidden?, hidden?)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:inner_block, assigns.inner_block)
    |> ok()
  end

  attr(:id, :string, required: true)

  slot(:inner_block, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <aside id={@id <> "-container"}>
      <.sidebar_slide_over id={@id} sidebar_hidden?={@hidden?} event_target={@myself}>
        <div class="grid grid-rows-[auto_auto_1fr_auto] h-full">
          <%= render_slot(@inner_block) %>
        </div>
      </.sidebar_slide_over>
    </aside>
    """
  end

  @impl true
  def handle_event("open-sidebar", _, socket) do
    socket
    |> assign(:hidden?, false)
    |> noreply()
  end

  @impl true
  def handle_event("close-sidebar", _, socket) do
    socket
    |> assign(:hidden?, true)
    |> noreply()
  end
end
