defmodule LiveDebugger.App.Debugger.Web.HookComponents.InspectButton do
  @moduledoc """
  This component is used to inspect the node.
  It produces `inspect-node` event handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.Client

  @impl true
  def init(socket) do
    Client.receive_events()

    socket
    |> check_assigns!([:lv_process])
    |> assign(:inspect_mode?, false)
    |> attach_hook(:inspect_button, :handle_info, &handle_info/2)
    |> attach_hook(:inspect_button, :handle_event, &handle_event/3)
    |> register_hook(:inspect_button)
  end

  attr(:inspect_mode?, :boolean, default: false)

  @impl true
  def render(assigns) do
    ~H"""
    <.nav_icon icon="icon-inspect" selected?={@inspect_mode?} phx-click="switch-inspect-mode" />
    """
  end

  defp handle_info({"element-inspected", %{"pid" => pid, "url" => url}}, socket) do
    if pid == inspect(self()) do
      socket
      |> redirect(external: url)
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

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("switch-inspect-mode", _, socket) do
    Client.push_event!(socket.assigns.root_socket_id, "inspect-mode-changed", %{
      inspect_mode: !socket.assigns.inspect_mode?,
      pid: inspect(self())
    })

    socket
    |> assign(:inspect_mode?, !socket.assigns.inspect_mode?)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
