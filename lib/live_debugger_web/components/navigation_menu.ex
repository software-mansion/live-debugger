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
    assigns =
      assign(assigns,
        pid: get_pid(assigns.current_url),
        current_view: get_current_view(assigns.current_url)
      )

    ~H"""
    <div class={[
      "flex flex-col gap-3 bg-sidebar-bg shadow-custom h-full p-2 border-r border-default-border"
      | List.wrap(@class)
    ]}>
      <.link navigate={RoutesHelper.channel_dashboard(@pid)}>
        <.nav_icon icon="icon-info" selected?={@current_view == "node_inspector"} />
      </.link>
      <.link navigate={RoutesHelper.global_traces(@pid)}>
        <.nav_icon icon="icon-globe" selected?={@current_view == "global_traces"} />
      </.link>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the navigation bar.")
  attr(:return_link, :any, required: true, doc: "Link to navigate to.")
  attr(:current_url, :any, required: true)

  def dropdown(assigns) do
    assigns =
      assign(assigns,
        pid: get_pid(assigns.current_url),
        current_view: get_current_view(assigns.current_url)
      )

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
          <LiveDropdown.dropdown_item
            icon="icon-info"
            label="Node Inspector"
            selected?={@current_view == "node_inspector"}
          />
        </.link>
        <.link navigate={RoutesHelper.global_traces(@pid)}>
          <LiveDropdown.dropdown_item
            icon="icon-globe"
            label="Global Callbacks"
            selected?={@current_view == "global_traces"}
          />
        </.link>
      </div>
    </.live_component>
    """
  end

  defp get_current_view(url) do
    url
    |> String.split("/")
    |> Enum.at(3, "node_inspector")
  end

  defp get_pid(url) do
    url
    |> String.split("/")
    |> Enum.at(2)
  end
end
