defmodule LiveDebuggerWeb.Components.NavigationMenu do
  @moduledoc """
  Set of components used in the navigation menu.
  """
  use LiveDebuggerWeb, :component

  alias LiveDebuggerWeb.LiveComponents.LiveDropdown

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")

  def sidebar(assigns) do
    ~H"""
    <div class={[
      "flex flex-col gap-3 bg-sidebar-bg shadow-custom h-full p-2 border-r border-default-border"
      | List.wrap(@class)
    ]}>
      <.nav_icon icon="icon-info" />
      <.nav_icon icon="icon-globe" />
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:return_link, :any, required: true, doc: "Link to navigate to.")

  def dropdown(assigns) do
    ~H"""
    <.live_component
      module={LiveDropdown}
      id="navigation-bar-dropdown"
      class={@class}
      direction="right"
    >
      <:button>
        <.nav_icon icon="icon-menu-hamburger" />
      </:button>
      <div class="min-w-44 flex flex-col p-1">
        <.link navigate={@return_link}>
          <LiveDropdown.dropdown_item icon="icon-arrow-left" label="Back to Home" />
        </.link>
        <span class="w-full border-b border-default-border my-1"></span>
        <LiveDropdown.dropdown_item icon="icon-info" label="Node Inspector" />
        <LiveDropdown.dropdown_item icon="icon-globe" label="Global Callbacks" />
      </div>
    </.live_component>
    """
  end
end
