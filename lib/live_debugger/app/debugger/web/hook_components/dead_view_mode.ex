defmodule LiveDebugger.App.Debugger.Web.HookComponents.DeadViewMode do
  @moduledoc """
  Hook component for displaying connection status.

  It handles events to manage DeadViewMode if it is enabled.
  """

  use LiveDebugger.App.Web, :hook_component

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Debugger.Queries.LvProcess, as: LvProcessQueries

  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied

  @impl true
  def init(socket) do
    socket
    |> check_private!(:pid)
    |> attach_hook(:dead_view_mode, :handle_info, &handle_info/2)
    |> attach_hook(:dead_view_mode, :handle_event, &handle_event/3)
    |> attach_hook(:dead_view_mode, :handle_async, &handle_async/3)
    |> register_hook(:dead_view_mode)
    |> put_private(:dead_view_mode?, SettingsStorage.get(:dead_view_mode))
  end

  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)

  @impl true
  def render(assigns) do
    connected? = assigns.lv_process.alive?

    assigns =
      assigns
      |> assign(:connected?, connected?)
      |> assign(:display_pid, Parsers.pid_to_string(assigns.lv_process.pid))
      |> assign(:tooltip_content, tooltip_content(connected?))

    ~H"""
    <.tooltip id={@id <> "-tooltip"} position="bottom" content={@tooltip_content}>
      <div id={@id} class="flex items-center gap-1 text-xs text-primary ml-1">
        <.status_icon connected?={@connected?} />
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

  attr(:connected?, :boolean, required: true)

  defp status_icon(assigns) do
    assigns =
      if assigns.connected? do
        assign(assigns, icon: "icon-check-circle", class: "text-(--swm-green-100)")
      else
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
    socket
    |> put_private(:dead_view_mode?, value)
    |> halt()
  end

  defp handle_info(%LiveViewDied{pid: pid}, %{private: %{pid: pid}} = socket) do
    if socket.private[:dead_view_mode?] do
      lv_process =
        socket.assigns.lv_process.result
        |> LvProcess.set_alive(false)
        |> AsyncResult.ok()

      socket
      |> assign(:lv_process, lv_process)
      |> halt()
    else
      socket
      |> start_async_find_successor()
      |> halt()
    end
  end

  defp handle_info(%LiveViewDied{}, socket), do: {:halt, socket}

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("find-successor", _params, socket) do
    socket
    |> start_async_find_successor()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_async(:find_successor, {:ok, %LvProcess{pid: pid}}, socket) do
    socket
    |> push_navigate(to: RoutesHelper.debugger_node_inspector(pid))
    |> halt()
  end

  defp handle_async(:find_successor, _, socket) do
    socket
    |> push_navigate(to: RoutesHelper.error("not_found"))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp start_async_find_successor(socket) do
    lv_process = socket.assigns.lv_process.result

    socket
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:find_successor, fn ->
      LvProcessQueries.get_successor_with_retries(lv_process)
    end)
  end
end
