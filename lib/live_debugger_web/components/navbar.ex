defmodule LiveDebuggerWeb.Components.Navbar do
  @moduledoc """
  Set of components used in the navbar.
  """

  use LiveDebuggerWeb, :component

  alias LiveDebuggerWeb.Helpers.RoutesHelper
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

  attr(:return_link, :any, required: true, doc: "Link to navigate to.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the link.")

  def return_link(assigns) do
    ~H"""
    <.link patch={@return_link} class={@class} id="return-button">
      <.nav_icon icon="icon-arrow-left" />
    </.link>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the link.")
  attr(:return_to, :any, default: nil, doc: "Return to URL.")

  def settings_button(assigns) do
    ~H"""
    <.link navigate={RoutesHelper.settings(@return_to)} class={@class} id="settings-button">
      <.nav_icon icon="icon-settings" />
    </.link>
    """
  end

  @doc """
  Component for displaying the connection status of a LiveView.
  When button is clicked, it will trigger a `find-successor` event with the PID of the LiveView.
  """
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true, doc: "The LiveView process.")
  attr(:rest, :global)

  def connected(%{lv_process: %{ok?: true}} = assigns) do
    connected? = assigns.lv_process.result.alive?
    status = if(connected?, do: :connected, else: :disconnected)

    assigns = assign(assigns, status: status, connected?: connected?)

    ~H"""
    <.tooltip id={@id} position="bottom" content={tooltip_content(@connected?)}>
      <div id={@id} class="flex items-center gap-1 text-xs text-primary ml-1">
        <.status_icon status={@status} />
        <%= if @connected? do %>
          <span class="font-medium">Monitored PID </span>
          <%= Parsers.pid_to_string(@lv_process.result.pid) %>
        <% else %>
          <span class="font-medium">Disconnected</span>
          <.button phx-click="find-successor" variant="secondary" size="sm">Continue</.button>
        <% end %>
      </div>
    </.tooltip>
    """
  end

  def connected(assigns) do
    ~H"""
    <div id={@id} class="flex items-center gap-1 text-xs text-primary ml-1">
      <.status_icon status={:loading} />
      <span class="font-medium">Loading LiveView process...</span>
    </div>
    """
  end

  attr(:status, :atom, required: true, values: [:connected, :disconnected, :loading])

  defp status_icon(assigns) do
    assigns =
      case(assigns.status) do
        :connected ->
          assign(assigns, icon: "icon-check-small", class: "bg-[--swm-green-100]")

        :disconnected ->
          assign(assigns, icon: "icon-cross-small", class: "bg-[--swm-pink-100]")

        :loading ->
          assign(assigns, icon: nil, class: "bg-[--swm-yellow-100] animate-pulse")
      end

    ~H"""
    <div class={["w-4 h-4 rounded-full flex items-center justify-center", @class]}>
      <.icon :if={@icon} name={@icon} class="bg-white w-4 h-4" />
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
