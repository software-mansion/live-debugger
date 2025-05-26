defmodule LiveDebuggerWeb.Components.NavigationMenu do
  @moduledoc """
  Set of components used in the navigation menu.
  """

  use LiveDebuggerWeb, :component

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

  def dropdown(assigns) do
    ~H"""
    <.live_component
      module={LiveDebuggerWeb.LiveComponents.LiveDropdown}
      id="navigation-bar-dropdown"
      class={@class}
    >
      <:button>
        <.nav_icon icon="icon-menu-hamburger" />
      </:button>
      Test
    </.live_component>
    """
  end
end
