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

  attr(:selected_interval, :integer,
    required: true,
    doc: "Currently selected refresh interval in milliseconds"
  )

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
        <.form for={%{}} phx-change="change_refresh_interval">
          <.radio_button
            :for={{label, value} <- @options}
            name={@name}
            value={value}
            label={label}
            checked={value == @selected_interval}
          />
        </.form>
      </div>
    </.live_component>
    """
  end
end
