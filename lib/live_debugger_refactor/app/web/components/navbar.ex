defmodule LiveDebuggerRefactor.App.Web.Components.Navbar do
  @moduledoc """
  Components used to create the navbar for the LiveDebugger application.
  """

  use LiveDebuggerRefactor.App.Web, :component

  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.App.Utils.Parsers

  @doc """
  Base navbar component. Wrap other components inside this to create a navbar.
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

  @spec fill(any()) :: Phoenix.LiveView.Rendered.t()
  @doc """
  Used to better layout the navbar when using grid.

  ## Examples

      <Navbar.navbar class="grid grid-cols-[1fr_auto_1fr]">
        <Navbar.return_link return_link={RoutesHelper.home()} />
        <Navbar.fill />
        <Navbar.settings_button return_to={@url} />
      </Navbar.navbar>
  """
  def fill(assigns) do
    ~H"""
    <div class="w-0 h-0"></div>
    """
  end

  @doc """
  LiveDebugger logo with text.
  """
  def live_debugger_logo(assigns) do
    ~H"""
    <.icon name="icon-logo-text" class="h-6 w-32" />
    """
  end

  @doc """
  LiveDebugger logo icon without text.
  """
  def live_debugger_logo_icon(assigns) do
    ~H"""
    <.icon name="icon-logo" class="h-6 w-6" />
    """
  end

  @doc """
  Link arrow to navigate to the `return_link` path.
  """
  attr(:return_link, :any, required: true, doc: "Link to navigate to.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the link.")

  def return_link(assigns) do
    ~H"""
    <.link patch={@return_link} class={@class} id="return-button">
      <.nav_icon icon="icon-arrow-left" />
    </.link>
    """
  end

  @doc """
  Settings button that navigates to the settings page.
  """
  attr(:class, :any, default: nil, doc: "Additional classes to add to the link.")
  attr(:return_to, :any, default: nil, doc: "URL which will be used to return from settings.")

  def settings_button(assigns) do
    ~H"""
    <.link navigate={RoutesHelper.settings(@return_to)} class={@class} id="settings-button">
      <.nav_icon icon="icon-settings" />
    </.link>
    """
  end

  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)

  def connected(assigns) do
    connected? = assigns.lv_process.alive?
    status = if(connected?, do: :connected, else: :disconnected)

    assigns =
      assigns
      |> assign(:status, status)
      |> assign(:connected?, connected?)
      |> assign(:display_pid, Parsers.pid_to_string(assigns.lv_process.pid))
      |> assign(:tooltip_content, tooltip_content(connected?))

    ~H"""
    <.tooltip id={@id <> "-tooltip"} position="bottom" content={@tooltip_content}>
      <div id={@id} class="flex items-center gap-1 text-xs text-primary ml-1">
        <.status_icon status={@status} />
        <%= if @connected? do %>
          <span class="font-medium">Monitored PID </span>
          <%= @display_pid %>
        <% else %>
          <span class="font-medium">Disconnected</span>
          <.button phx-click="find-successor" variant="secondary" size="sm">Continue</.button>
        <% end %>
      </div>
    </.tooltip>
    """
  end

  attr(:status, :atom, required: true, values: [:connected, :disconnected])

  defp status_icon(assigns) do
    assigns =
      case(assigns.status) do
        :connected ->
          assign(assigns, icon: "icon-check-circle", class: "text-(--swm-green-100)")

        :disconnected ->
          assign(assigns, icon: "icon-cross-circle", class: "text-(--swm-pink-100)")
      end

    ~H"""
    <div class={["w-4 h-4 rounded-full flex items-center justify-center", @class]}>
      <.icon :if={@icon} name={@icon} class={["w-4 h-4", @class]} />
    </div>
    """
  end

  defp tooltip_content(true) do
    "LiveView process is alive"
  end

  defp tooltip_content(false) do
    "LiveView process is dead - you can still debug the last state"
  end
end
