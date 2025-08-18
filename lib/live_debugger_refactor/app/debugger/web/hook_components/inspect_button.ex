defmodule LiveDebuggerRefactor.App.Debugger.Web.HookComponents.InspectButton do
  @moduledoc """
  This component is used to inspect the node.
  It produces `inspect-node` event handled by hook added via `init/1`.
  """

  use LiveDebuggerRefactor.App.Web, :hook_component

  alias LiveDebuggerRefactor.Client
  alias LiveDebuggerRefactor.API.LiveViewDebug

  @impl true
  def init(socket) do
    Client.receive_events()

    socket
    |> check_private!(:pid)
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

  defp handle_info(:inspect_node, socket) do
    socket
    |> assign(:inspect_node, true)
    |> halt()
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
    pid = socket.private.pid
    inspect_mode? = !socket.assigns.inspect_mode?

    # Well it cannot stay like this, but we need root pid...
    case LiveViewDebug.socket(pid) do
      {:ok, %{root_pid: root_pid, id: socket_id}} when root_pid == pid ->
        Client.push_event!(socket_id, "inspect-mode-changed", %{
          inspect_mode: inspect_mode?,
          pid: inspect(self())
        })

      {:ok, %{root_pid: root_pid}} when root_pid != pid ->
        LiveViewDebug.socket(root_pid)
        |> case do
          {:ok, %{id: socket_id}} ->
            Client.push_event!(socket_id, "inspect-mode-changed", %{
              inspect_mode: inspect_mode?,
              pid: inspect(self())
            })
        end

      _ ->
        nil
    end

    socket
    |> assign(:inspect_mode?, inspect_mode?)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
