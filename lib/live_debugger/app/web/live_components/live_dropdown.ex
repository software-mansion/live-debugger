defmodule LiveDebugger.App.Web.LiveComponents.LiveDropdown do
  @moduledoc """
  Dropdown LiveComponent that can be used to display a dropdown menu
  """

  use LiveDebugger.App.Web, :live_component

  @doc """
  Closes the dropdown. You can use it when you want to close the dropdown from other component.
  """
  def close(id) do
    send_update(__MODULE__, id: id, action: :close)
  end

  @impl true
  def update(%{action: :close}, socket) do
    {:ok, assign(socket, :open, false)}
  end

  @impl true
  def update(assigns, %{assigns: %{mounted?: true}} = socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:class, assigns[:class] || "")
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:class, assigns[:class] || "")
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> assign(:open, assigns[:open] || false)
    |> assign(:mounted?, true)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:open, :boolean, required: true, doc: "Whether the dropdown is open")
  attr(:class, :string, default: "", doc: "Additional classes to add to the dropdown container")

  slot(:button, required: true)
  slot(:inner_block, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id <> "-live-dropdown-container"} class={["relative", @class]} phx-hook="LiveDropdown">
      <div id={@id <> "-button"} phx-click={if !@open, do: "open"} phx-target={@myself}>
        <%= render_slot(@button) %>
      </div>

      <div
        :if={@open}
        id={@id <> "-content"}
        class="absolute bg-surface-0-bg rounded border border-default-border mt-1 z-50 left-0"
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("open", _, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  @impl true
  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end
end
