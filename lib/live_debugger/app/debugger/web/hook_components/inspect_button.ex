defmodule LiveDebugger.App.Debugger.Web.HookComponents.InspectButton do
  @moduledoc """
  This component is used to inspect the node.
  It produces `inspect-node` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered
  alias LiveDebugger.Client
  alias LiveDebugger.Structs.LvProcess

  alias LiveDebugger.App.Utils.URL

  @impl true
  def init(socket) do
    # TODO: retrieve window_id from server (mechanism not implemented yet)
    window_id = "TODO"
    Client.receive_events(window_id)

    socket
    |> check_assigns!([:lv_process])
    |> assign(:inspect_mode?, false)
    |> attach_hook(:inspect_button, :handle_info, &handle_info/2)
    |> attach_hook(:inspect_button, :handle_event, &handle_event/3)
    |> register_hook(:inspect_button)
  end

  attr(:inspect_mode?, :boolean, default: false)
  attr(:lv_process, LvProcess, required: true)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :disabled?, !assigns.lv_process.alive?)

    ~H"""
    <div class="flex items-center pr-1">
      <div class="border-r-2 border-default-border pr-2">
        <.tooltip id="inspect-button-tooltip" position="bottom" content="Inspect element on the page">
          <.nav_icon
            icon="icon-inspect"
            selected?={@inspect_mode?}
            phx-click="switch-inspect-mode"
            disabled?={@disabled?}
            icon_class="!w-5 !h-5"
          />
        </.tooltip>
      </div>
    </div>
    """
  end

  defp handle_info(%DeadViewModeEntered{debugger_pid: pid}, socket) when pid == self() do
    # TODO: retrieve window_id from server (mechanism not implemented yet)
    window_id = "TODO"
    Client.push_event!(window_id, "inspect-mode-changed", %{
      inspect_mode: false,
      pid: inspect(self())
    })

    socket
    |> assign(:inspect_mode?, false)
    |> halt()
  end

  defp handle_info({"element-inspected", %{"pid" => pid, "url" => url}}, socket) do
    if pid == inspect(self()) do
      socket
      |> redirect(external: URL.upsert_query_param(url, "from", "inspect_button"))
      |> halt()
    else
      {:halt, socket}
    end
  end

  defp handle_info(
         {"inspect-mode-changed", %{"inspect_mode" => inspect_mode?, "pid" => pid}},
         socket
       ) do
    if pid == inspect(self()) do
      socket
      |> assign(:inspect_mode?, inspect_mode?)
      |> halt()
    else
      {:halt, socket}
    end
  end

  defp handle_info(:switch_inspect_mode, socket) do
    switch_inspect_mode(socket)
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("switch-inspect-mode", _, socket) do
    switch_inspect_mode(socket)
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp switch_inspect_mode(socket) do
    # TODO: retrieve window_id from server (mechanism not implemented yet)
    window_id = "TODO"
    Client.push_event!(window_id, "inspect-mode-changed", %{
      inspect_mode: !socket.assigns.inspect_mode?,
      pid: inspect(self())
    })

    socket
    |> assign(:inspect_mode?, !socket.assigns.inspect_mode?)
    |> halt()
  end
end
