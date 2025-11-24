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
      "flex flex-row gap-3 bg-sidebar-bg shadow-custom w-full h-max pt-1 px-2 border-r border-default-border"
      | List.wrap(@class)
    ]}>
      <.sidebar_item
        id="node-inspector-sidebar-item"
        content="Node Inspector"
        patch={RoutesHelper.debugger_node_inspector(@pid)}
        icon="icon-info"
        selected?={@current_view == "node_inspector"}
      />

      <.sidebar_item
        id="global-traces-sidebar-item"
        content="Global Callbacks"
        patch={RoutesHelper.debugger_global_traces(@pid)}
        icon="icon-globe"
        selected?={@current_view == "global_traces"}
      />

      <.sidebar_item
        id="resources-sidebar-item"
        content="Resources"
        patch={RoutesHelper.debugger_resources(@pid)}
        icon="icon-chart-line"
        selected?={@current_view == "resources"}
      />
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
        <.dropdown_item
          icon="icon-chart-line"
          label="Resources"
          selected?={@current_view == "resources"}
          phx-click={dropdown_item_click(RoutesHelper.debugger_resources(@pid))}
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
      class={[
        "flex gap-1.5 p-2 rounded items-center w-full hover:bg-surface-0-bg-hover cursor-pointer",
        if(@selected?, do: "bg-surface-0-bg-hover font-semibold")
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-4 w-4" />
      <span>{@label}</span>
    </div>
    """
  end

  # We do it to make sure that the dropdown is closed when the item is clicked.
  defp dropdown_item_click(url) do
    url
    |> JS.patch()
    |> JS.push("close", target: "#navigation-bar-dropdown-live-dropdown-container")
  end

  attr(:id, :string, required: true)
  attr(:patch, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:selected?, :boolean, default: false)
  attr(:content, :string, required: true)

  def sidebar_item(assigns) do
    ~H"""
    <div id={@id} class={["w-max", @selected? && "border-b-2"]}>
      <.link patch={@patch}>
        <div class="flex flex-row items-center justify-center w-full mt-1 mb-2">
          <.icon name={@icon} class="h-4 w-4" />

          <span class="text-xs font-medium text-center pl-1">
            {@content}
          </span>
        </div>
      </.link>
    </div>
    """
  end

  defp get_current_view(url) do
    URL.take_nth_segment(url, 3) || "node_inspector"
  end

  defp get_pid(url) do
    URL.take_nth_segment(url, 2)
  end
end
