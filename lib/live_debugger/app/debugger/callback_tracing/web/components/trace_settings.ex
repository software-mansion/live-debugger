defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Components.TraceSettings do
  @moduledoc """
  UI components for trace settings.
  """
  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents

  alias Phoenix.LiveView.JS

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:current_filters, :map, required: true)

  def dropdown_menu(assigns) do
    ~H"""
    <.live_component
      module={LiveDropdown}
      id="tracing-options-dropdown"
      class={@class}
      direction={:bottom_left}
    >
      <:button>
        <.nav_icon
          icon="icon-chevron-right"
          class="border-button-secondary-border border hover:border-button-secondary-border-hover"
        />
      </:button>
      <div class="min-w-44 flex flex-col p-1">
        <div phx-click={dropdown_item_click()}>
          <HookComponents.RefreshButton.render
            display_mode={:dropdown}
            phx-click={dropdown_item_click()}
          />
        </div>
        <HookComponents.ClearButton.render display_mode={:dropdown} phx-click={dropdown_item_click()} />
        <HookComponents.FiltersFullscreen.filters_button
          current_filters={@current_filters}
          display_mode={:dropdown}
          phx-click={dropdown_item_click()}
        />
      </div>
    </.live_component>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)

  def dropdown_item(assigns) do
    ~H"""
    <div class="flex gap-1.5 p-2 rounded items-center w-full hover:bg-surface-0-bg-hover cursor-pointer">
      <.icon name={@icon} class="w-4 h-4" />
      <span>{@label}</span>
    </div>
    """
  end

  defp dropdown_item_click() do
    JS.push("close", target: "#tracing-options-dropdown-live-dropdown-container")
  end
end
