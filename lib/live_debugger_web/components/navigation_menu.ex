defmodule LiveDebuggerWeb.Components.NavigationMenu do
  @moduledoc """
  Set of components used in the navigation menu.
  """
  use LiveDebuggerWeb, :component

  alias LiveDebuggerWeb.LiveComponents.LiveDropdown
  alias LiveDebuggerWeb.Helpers.RoutesHelper
  alias LiveDebugger.Utils.URL
  alias Phoenix.LiveView.JS

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
      <.tooltip id="node-inspector-tooltip" position="right" content="Node Inspector">
        <.link patch={RoutesHelper.channel_dashboard(@pid)}>
          <.nav_icon icon="icon-info" selected?={@current_view == "node_inspector"} />
        </.link>
      </.tooltip>
      <.tooltip id="global-traces-tooltip" position="right" content="Global Callbacks">
        <.link patch={RoutesHelper.global_traces(@pid)}>
          <.nav_icon icon="icon-globe" selected?={@current_view == "global_traces"} />
        </.link>
      </.tooltip>
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
        <.link patch={@return_link}>
          <LiveDropdown.dropdown_item icon="icon-arrow-left" label="Back to Home" />
        </.link>
        <span class="w-full border-b border-default-border my-1"></span>
        <LiveDropdown.dropdown_item
          icon="icon-info"
          label="Node Inspector"
          selected?={@current_view == "node_inspector"}
          phx-click={dropdown_item_click(RoutesHelper.channel_dashboard(@pid))}
        />
        <LiveDropdown.dropdown_item
          icon="icon-globe"
          label="Global Callbacks"
          selected?={@current_view == "global_traces"}
          phx-click={dropdown_item_click(RoutesHelper.global_traces(@pid))}
        />
      </div>
    </.live_component>
    """
  end

  # We do it to make sure that the dropdown is closed when the item is clicked.
  defp dropdown_item_click(url) do
    url
    |> JS.patch()
    |> JS.push("close", target: "#navigation-bar-dropdown-live-dropdown-container")
  end

  defp get_current_view(url) do
    URL.take_nth_segment(url, 3) || "node_inspector"
  end

  defp get_pid(url) do
    URL.take_nth_segment(url, 2)
  end
end
