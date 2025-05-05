defmodule LiveDebuggerWeb.LiveComponents.LiveDropdown do
  @moduledoc """
  Dropdown component that can be used to display a dropdown menu written via LiveComponents.
  """

  use LiveDebuggerWeb, :live_component

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
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:button, assigns.button)
    |> assign(:inner_block, assigns.inner_block)
    |> assign(:open, assigns[:open] || false)
    |> assign(:mounted?, true)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:open, :boolean, required: true)

  slot :button, required: true do
    attr(:class, :any, doc: "Additional classes to add to the button.")

    attr(:size, :string,
      values: ["sm", "md"],
      doc: "Size of the button."
    )

    attr(:variant, :string,
      values: ["primary", "secondary"],
      doc: "Variant of the button."
    )
  end

  slot(:inner_block, required: true)

  def render(assigns) do
    ~H"""
    <div id={@id <> "-live-dropdown-container"} class="relative" phx-hook="LiveDropdown">
      <.button
        :for={button_slot <- @button}
        class={Map.get(button_slot, :class)}
        variant={Map.get(button_slot, :variant, "secondary")}
        size={Map.get(button_slot, :size, "sm")}
        id={@id <> "-button"}
        phx-click={if !@open, do: "open"}
        phx-target={@myself}
      >
        <%= render_slot(button_slot) %>
      </.button>

      <div
        :if={@open}
        id={@id <> "-content"}
        class="absolute right-0 bg-surface-0-bg rounded border border-default-border mt-1 z-50"
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
