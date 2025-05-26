defmodule LiveDebuggerWeb.LiveComponents.LiveDropdown do
  @moduledoc """
  Dropdown component that can be used to display a dropdown menu written via LiveComponents.
  """

  use LiveDebuggerWeb, :live_component

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:link, :string, default: nil)
  attr(:selected?, :boolean, default: false)

  @spec dropdown_item(map()) :: Phoenix.LiveView.Rendered.t()
  def dropdown_item(assigns) do
    ~H"""
    <div class="flex gap-1.5 p-2 rounded items-center w-full hover:bg-surface-0-bg-hover cursor-pointer">
      <.icon name={@icon} class="h-4 w-4" />
      <span class={if @selected?, do: "font-semibold"}>{@label}</span>
    </div>
    """
  end

  @doc """
  Closes the dropdown. You can use it when you want to close the dropdown from other component.
  """
  def close(id) do
    send_update(LiveDebuggerWeb.LiveComponents.LiveDropdown, id: id, action: :close)
  end

  def update(%{action: :close}, socket) do
    {:ok, assign(socket, :open, false)}
  end

  def update(assigns, %{assigns: %{mounted?: true}} = socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:class, assigns[:class] || "")
    |> assign(:direction, assigns[:direction] || "left")
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:class, assigns[:class] || "")
    |> assign(:direction, assigns[:direction] || "left")
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> assign(:open, assigns[:open] || false)
    |> assign(:mounted?, true)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:open, :boolean, required: true)
  attr(:class, :string, default: "")
  attr(:direction, :string, default: "left")

  slot(:button, required: true)
  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <div
      id={@id <> "-live-dropdown-container"}
      class={[
        "relative",
        @class
      ]}
      phx-hook="LiveDropdown"
    >
      <div id={@id <> "-button"} phx-click={if !@open, do: "open"} phx-target={@myself}>
        <%= render_slot(@button) %>
      </div>

      <div
        :if={@open}
        id={@id <> "-content"}
        class={[
          "absolute bg-surface-0-bg rounded border border-default-border mt-1 z-50",
          @direction == "left" && "right-0",
          @direction == "right" && "left-0"
        ]}
      >
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  def handle_event("open", _, socket) do
    {:noreply, assign(socket, :open, true)}
  end

  def handle_event("close", _, socket) do
    {:noreply, assign(socket, :open, false)}
  end
end
