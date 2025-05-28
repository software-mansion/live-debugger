defmodule LiveDebuggerWeb.Components.NavigationMenu do
  @moduledoc """
  Set of components used in the navigation menu.
  """
  use LiveDebuggerWeb, :component

  alias LiveDebuggerWeb.LiveComponents.LiveDropdown
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:current_url, :any, required: true)

  def sidebar(assigns) do
    pid = assigns.current_url |> String.split("/") |> Enum.at(2)
    assigns = assign(assigns, pid: pid)

    ~H"""
    <div class={[
      "flex flex-col gap-3 bg-sidebar-bg shadow-custom h-full p-2 border-r border-default-border"
      | List.wrap(@class)
    ]}>
      <.link navigate={RoutesHelper.channel_dashboard(@pid)}>
        <.nav_icon icon="icon-info" />
      </.link>
      <.link navigate={RoutesHelper.global_traces(@pid)}>
        <.nav_icon icon="icon-globe" />
      </.link>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:return_link, :any, required: true, doc: "Link to navigate to.")
  attr(:current_url, :any, required: true)

  def dropdown(assigns) do
    pid = assigns.current_url |> String.split("/") |> Enum.at(2)
    assigns = assign(assigns, pid: pid)

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
        <.link navigate={RoutesHelper.channel_dashboard(@pid)}>
          <LiveDropdown.dropdown_item icon="icon-info" label="Node Inspector" />
        </.link>
        <.link navigate={RoutesHelper.global_traces(@pid)}>
          <LiveDropdown.dropdown_item icon="icon-globe" label="Global Callbacks" />
        </.link>
      </div>
    </.live_component>
    """
  end
end
