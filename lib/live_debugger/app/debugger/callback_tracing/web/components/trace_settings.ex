defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Components.TraceSettings do
  @moduledoc """
  UI components for trace settings.
  """
  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:current_filters, :map, required: true)
  attr(:id, :string, required: true)

  def node_traces_dropdown_menu(assigns) do
    ~H"""
    <.live_component module={LiveDropdown} id={@id} class={@class} direction={:bottom_left}>
      <:button>
        <.dropdown_button />
      </:button>
      <div class="min-w-44 flex flex-col">
        <HookComponents.RefreshButton.render display_mode={:dropdown} />

        <HookComponents.ClearButton.render display_mode={:dropdown} />

        <HookComponents.FiltersFullscreen.filters_button
          current_filters={@current_filters}
          display_mode={:dropdown}
        />
      </div>
    </.live_component>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")

  def global_traces_dropdown_menu(assigns) do
    ~H"""
    <.live_component
      module={LiveDropdown}
      id="tracing-options-dropdown"
      class={@class}
      direction={:bottom_left}
    >
      <:button>
        <.dropdown_button />
      </:button>
      <div class="min-w-44 flex flex-col">
        <HookComponents.RefreshButton.render display_mode={:dropdown} />
        <HookComponents.ClearButton.render display_mode={:dropdown} />
      </div>
    </.live_component>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)

  def dropdown_item(assigns) do
    ~H"""
    <div class="flex gap-1.5 p-2 rounded items-center w-full">
      <.icon name={@icon} class="w-4 h-4" />
      <span>{@label}</span>
    </div>
    """
  end

  attr(:display_mode, :atom, required: true)
  attr(:id, :string, required: true)
  attr(:content, :string, required: true)
  attr(:position, :string, default: "top-center")

  slot(:inner_block, required: true)

  def maybe_add_tooltip(assigns) do
    ~H"""
    <%= if @display_mode == :normal do %>
      <.tooltip id={@id} content={@content} position={@position}>
        <%= render_slot(@inner_block) %>
      </.tooltip>
    <% else %>
      <%= render_slot(@inner_block) %>
    <% end %>
    """
  end

  attr(:display_mode, :atom, required: true)
  attr(:icon, :string, required: true)
  attr(:label, :string, default: nil)

  def action_icon(assigns) do
    ~H"""
    <%= if @display_mode == :normal do %>
      <.icon name={@icon} class="w-4 h-4" />
    <% else %>
      <.dropdown_item icon={@icon} label={@label} />
    <% end %>
    """
  end

  defp dropdown_button(assigns) do
    ~H"""
    <.nav_icon
      icon="icon-chevrons-right"
      class="border-button-secondary-border border hover:border-button-secondary-border-hover w-8! h-7!"
      icon_class="!h-4 !w-4"
    />
    """
  end
end
