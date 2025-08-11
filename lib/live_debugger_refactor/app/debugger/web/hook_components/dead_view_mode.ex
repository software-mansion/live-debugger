defmodule LiveDebuggerRefactor.App.Debugger.Web.HookComponents.DeadViewMode do
  @moduledoc """
  Hook component for displaying connection status.

  It handles events to manage DeadViewMode if it is enabled.
  """

  use LiveDebuggerRefactor.App.Web, :hook_component

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.API.SettingsStorage
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.UserChangedSettings
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Events.LiveViewDied

  @impl true
  def init(socket) do
    Bus.receive_events!()

    socket
    |> attach_hook(:dead_view_mode, :handle_info, &handle_info/2)
    |> attach_hook(:dead_view_mode, :handle_event, &handle_event/3)
    |> register_hook(:dead_view_mode)
    |> put_private(:dead_view_mode?, SettingsStorage.get(:dead_view_mode))
  end

  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)

  @impl true
  def render(assigns) do
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

  defp handle_info(%UserChangedSettings{key: :dead_view_mode, value: value}, socket) do
    if value do
      socket
      |> put_private(:dead_view_mode?, true)
    else
      socket
      |> put_private(:dead_view_mode?, false)
    end
    |> halt()
  end

  defp handle_info(
         %LiveViewDied{pid: pid},
         %{
           assigns: %{
             lv_process: %{result: %LvProcess{pid: pid} = lv_process_result}
           }
         } = socket
       ) do
    if socket.private[:dead_view_mode?] do
      lv_process_result = %LvProcess{lv_process_result | alive?: false}
      lv_process = %AsyncResult{socket.assigns.lv_process | result: lv_process_result}

      socket
      |> assign(:lv_process, lv_process)
      |> halt()
    else
      socket
      |> push_navigate(to: RoutesHelper.discovery())
      |> halt()
    end
  end

  defp handle_info(%LiveViewDied{}, socket), do: {:cont, socket}

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("find-successor", _params, socket) do
    socket
    |> push_navigate(to: RoutesHelper.discovery())
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
