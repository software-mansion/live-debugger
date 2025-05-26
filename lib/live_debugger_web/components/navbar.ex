defmodule LiveDebuggerWeb.Components.Navbar do
  @moduledoc """
  Set of components used in the navbar.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebugger.Utils.Parsers

  @doc """
  Renders base navbar component.
  """
  attr(:class, :string, default: "", doc: "Additional classes to add to the navbar.")

  slot(:inner_block, required: true)

  def navbar(assigns) do
    ~H"""
    <navbar class={[
      "w-full min-w-max h-12 shrink-0 py-auto px-4 gap-2 items-center bg-navbar-bg text-navbar-logo border-b border-navbar-border",
      @class
    ]}>
      <%= render_slot(@inner_block) %>
    </navbar>
    """
  end

  @doc """
  Used to better layout the navbar when using grid.
  """
  def fill(assigns) do
    ~H"""
    <div class="w-0 h-0"></div>
    """
  end

  @doc """
  Renders the LiveDebugger logo with text in the navbar.
  """
  def live_debugger_logo(assigns) do
    ~H"""
    <.icon name="icon-logo-text" class="h-6 w-32" />
    """
  end

  @doc """
  Renders the LiveDebugger logo icon in the navbar.
  """
  def live_debugger_logo_icon(assigns) do
    ~H"""
    <.icon name="icon-logo" class="h-6 w-6" />
    """
  end

  @doc """
  Renders a link to return to the previous page.
  """
  attr(:link, :any, required: true, doc: "Link to navigate to.")

  def return_link(assigns) do
    ~H"""
    <.link patch={@link}>
      <.nav_icon icon="icon-arrow-left" />
    </.link>
    """
  end

  @doc """
  Renders a theme toggle button.
  """
  # TODO: move it to settings page
  def theme_toggle(assigns) do
    ~H"""
    <div class="flex">
      <.nav_icon id="light-mode-switch" class="dark:hidden" icon="icon-moon" phx-hook="ToggleTheme" />
      <.nav_icon
        id="dark-mode-switch"
        class="hidden dark:block"
        icon="icon-sun"
        phx-hook="ToggleTheme"
      />
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the link.")

  def settings_button(assigns) do
    ~H"""
    <.link class={@class}>
      <.nav_icon icon="icon-settings" />
    </.link>
    """
  end

  @doc """
  Renders an icon with navbar styles.
  """
  attr(:icon, :string, required: true, doc: "Icon to be displayed.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the nav icon.")

  attr(:rest, :global, include: ~w(id))

  def nav_icon(assigns) do
    ~H"""
    <button
      aria-label={Parsers.kebab_to_text(@icon)}
      class={[
        "w-8! h-8! px-[0.25rem] py-[0.25rem] w-max h-max rounded text-xs font-semibold text-navbar-icon hover:text-navbar-icon-hover hover:bg-navbar-icon-bg-hover"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-6 w-6" />
    </button>
    """
  end

  @doc """
  Component for displaying the connection status of a LiveView.
  When button is clicked, it will trigger a `find-successor` event with the PID of the LiveView.
  """
  attr(:id, :string, required: true)
  attr(:connected?, :boolean, required: true, doc: "Whether LiveView is connected.")
  attr(:pid, :string, required: true, doc: "The PID of the LiveView.")
  attr(:rest, :global)

  def connected(assigns) do
    ~H"""
    <.tooltip
      id={@id}
      position="bottom"
      content={
        if(@connected?,
          do: "LiveView process is alive.",
          else: "LiveView process is dead. You can still debug the last state."
        )
      }
    >
      <div id={@id} class="flex items-center gap-1 text-xs text-primary">
        <.status_icon connected?={@connected?} />
        <%= if @connected? do %>
          <span class="font-medium">Monitored PID </span>
          <%= @pid %>
        <% else %>
          <span class="font-medium">Disconnected</span>
          <.button phx-click="find-successor" variant="secondary" size="sm">Continue</.button>
        <% end %>
      </div>
    </.tooltip>
    """
  end

  attr(:connected?, :boolean, required: true)

  defp status_icon(assigns) do
    ~H"""
    <div class={[
      "w-4 h-4 rounded-full flex items-center justify-center",
      if(@connected?, do: "bg-[--swm-green-100]", else: "bg-[--swm-pink-100]")
    ]}>
      <.icon
        name={if(@connected?, do: "icon-check-small", else: "icon-cross-small")}
        class="bg-white w-4 h-4"
      />
    </div>
    """
  end
end
