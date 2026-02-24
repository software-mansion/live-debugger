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

  alias LiveDebugger.Bus
  alias LiveDebugger.Client
  alias LiveDebugger.App.Events.UserChangedSettings
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered
  alias LiveDebugger.API.LiveViewDiscovery

  @impl true
  def init(socket) do
    socket
    |> check_private!(:pid)
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

    assigns =
      assigns
      |> assign(:connected?, connected?)
      |> assign(:display_pid, Parsers.pid_to_string(assigns.lv_process.pid))
      |> assign(:tooltip_content, tooltip_content(connected?))

    ~H"""
    <.tooltip id={@id <> "-tooltip"} position="bottom" content={@tooltip_content}>
      <div class="flex items-center gap-2 flex-row">
        <div
          id={@id}
          class={[
            "flex items-center gap-1 text-xs text-primary ml-1 rounded-xl py-1 px-2 w-max text-disconnected-text",
            @connected? && "bg-monitored-pid-bg",
            !@connected? && "bg-disconnected-bg"
          ]}
        >
          <.status_icon connected?={@connected?} />
          <%= if @connected? do %>
            <span class="font-medium">Monitored PID </span>
            <span class="font-light"><%= @display_pid %></span>
          <% else %>
            <span class="font-medium">Disconnected</span>
          <% end %>
        </div>
        <.button :if={!@connected?} phx-click="find-successor" variant="secondary" size="sm">
          Continue
        </.button>
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

      Bus.broadcast_event!(%DeadViewModeEntered{debugger_pid: self()}, self())

      socket
      |> assign(:lv_process, lv_process)
      |> halt()
    else
      socket
      |> start_successor_finding()
      |> halt()
    end
  end

  defp handle_info(%LiveViewDied{}, socket), do: {:halt, socket}

  defp handle_info({"found-successor", params}, socket) do
    dbg(params)

    # The problem is that there is a chance that the DOM has not bee updated yet and me may receive old socket id here
    # that is not binded to any active LiveView
    socket
    |> redirect(to: "/redirect/#{params["socket_id"]}")
    |> halt()
  end

  defp handle_info(:successor_not_found, socket) do
    socket
    |> put_flash(:error, "Successor not found")
    |> push_navigate(to: RoutesHelper.discovery())
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("find-successor", _params, socket) do
    socket
    |> start_successor_finding()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp start_successor_finding(socket) do
    case find_successor_by_transport_pid(socket.assigns.lv_process.result) do
      nil ->
        # If no successor is found with transport pid, we're asking browser to find successor.
        Client.push_event!(socket.assigns.lv_process.result.window_id, "find-successor")
        Process.send_after(self(), :successor_not_found, 2000)
        assign(socket, :lv_process, AsyncResult.loading())

      successor ->
        redirect(socket, to: RoutesHelper.debugger(successor.pid, socket.assigns.live_action))
    end
  end

  defp find_successor_by_transport_pid(lv_process) do
    transport_processes = LiveViewDiscovery.debugged_lv_processes(lv_process.transport_pid)

    find_first_match([
      # Priority 1: Find a non-nested, non-embedded process with matching transport_pid
      fn -> find_non_nested_non_embedded(transport_processes) end,
      # Priority 2: Use single process with matching transport_pid if it exists
      fn -> find_single_process(transport_processes) end
    ])
  end

  defp find_first_match(functions) do
    Enum.reduce_while(functions, nil, fn fun, _acc ->
      case fun.() do
        nil -> {:cont, nil}
        result -> {:halt, result}
      end
    end)
  end

  defp find_non_nested_non_embedded(processes) do
    Enum.find(processes, &(not &1.nested? and not &1.embedded?))
  end

  defp find_single_process(processes) do
    if length(processes) == 1, do: List.first(processes), else: nil
  end
end
