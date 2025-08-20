defmodule LiveDebugger.App.Debugger.Web.Components.NavigationMenu do
  @moduledoc """
  Set of components used to create a navigation menu for the debugger.
  """
  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Utils.URL
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
        <.link patch={RoutesHelper.debugger_node_inspector(@pid)}>
          <.nav_icon icon="icon-info" selected?={@current_view == "node_inspector"} />
        </.link>
      </.tooltip>
      <.tooltip id="global-traces-tooltip" position="right" content="Global Callbacks">
        <.link patch={RoutesHelper.debugger_global_traces(@pid)}>
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
    <.live_component module={LiveDropdown} id="navigation-bar-dropdown" class={@class}>
      <:button>
        <.nav_icon icon="icon-menu-hamburger" />
      </:button>
      <div class="min-w-44 flex flex-col p-1">
        <.link patch={@return_link}>
          <.dropdown_item icon="icon-arrow-left" label="Back to Home" />
        </.link>
        <span class="w-full border-b border-default-border my-1"></span>
        <.dropdown_item
          icon="icon-info"
          label="Node Inspector"
          selected?={@current_view == "node_inspector"}
          phx-click={dropdown_item_click(RoutesHelper.debugger_node_inspector(@pid))}
        />
        <.dropdown_item
          icon="icon-globe"
          label="Global Callbacks"
          selected?={@current_view == "global_traces"}
          phx-click={dropdown_item_click(RoutesHelper.debugger_global_traces(@pid))}
        />
      </div>
    </.live_component>
    """
  end

  attr(:icon, :string, required: true)
  attr(:label, :string, required: true)
  attr(:selected?, :boolean, default: false)
  attr(:rest, :global, include: [:phx_click])

  def dropdown_item(assigns) do
    ~H"""
    <div
      class="flex gap-1.5 p-2 rounded items-center w-full hover:bg-surface-0-bg-hover cursor-pointer"
      {@rest}
    >
      <.icon name={@icon} class="h-4 w-4" />
      <span class={if @selected?, do: "font-semibold"}>{@label}</span>
    </div>
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
