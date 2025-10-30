defmodule LiveDebugger.App.Debugger.Resources.Components do
  @moduledoc """
  Set of components for displaying resources information.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown

  @refresh_intervals [
    {"1 second", 1000},
    {"5 seconds", 5000},
    {"15 seconds", 15000},
    {"30 seconds", 30000}
  ]

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:class, :string, default: "", doc: "Additional classes to add to the dropdown container")

  def refresh_select(assigns) do
    assigns = assign(assigns, :options, @refresh_intervals)

    ~H"""
    <.live_component
      module={LiveDropdown}
      id="navigation-bar-dropdown"
      class={@class}
      direction={:bottom_left}
    >
      <:button>
        <.nav_icon icon="icon-menu-hamburger" />
      </:button>
      <div class="min-w-44 flex flex-col p-2 gap-1">
        <label
          :for={{label, value} <- @options}
          class="flex items-center gap-2 px-3 py-2 rounded cursor-pointer hover:bg-surface-1-bg transition-colors"
        >
          <input
            type="radio"
            name={@name}
            value={value}
            checked={value == 1000}
            class="w-4 h-4 text-ui-accent border border-default-border"
          />
          <span class="text-xs"><%= label %></span>
        </label>
      </div>
    </.live_component>
    """
  end
end
