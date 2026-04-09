defmodule LiveDebugger.App.Web.HookComponents.Tour do
  @moduledoc """
  Hook component that handles tour events across all LiveView pages.

  Subscribes to `client:tour:receive` PubSub topic and forwards tour actions
  to the Tour JS hook via `push_event`. Also handles `step-completed` events
  from the JS hook and sends them back to the client app.

  ## Usage

      # In init_debugger/mount:
      HookComponents.Tour.init(socket)

      # In template (root element):
      <div id="my-page" phx-hook="Tour">
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.Client

  @impl true
  def init(socket) do
    if Phoenix.LiveView.connected?(socket) do
      Client.receive_tour_events()
    end

    socket
    |> attach_hook(:tour, :handle_info, &handle_info/2)
    |> attach_hook(:tour, :handle_event, &handle_event/3)
    |> register_hook(:tour)
  end

  @impl true
  def render(assigns) do
    ~H""
  end

  defp handle_event("step-completed", %{"target" => _target} = payload, socket) do
    send_step_completed(socket, payload)

    socket
    |> halt()
  end

  defp handle_event("tour-redirect", %{"url" => url}, socket) do
    socket
    |> Phoenix.LiveView.push_navigate(to: url)
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_info({"tour:" <> action, payload}, socket) do
    tour_step = Map.put(payload, "action", action)

    {:cont, socket |> push_event("tour-action", tour_step)}
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp send_step_completed(socket, payload) do
    case socket.assigns do
      %{lv_process: %{ok?: true, result: %{root_socket_id: root_socket_id}}} ->
        Client.push_event!(root_socket_id, "step-completed", payload)

      _ ->
        Client.push_event!("*", "step-completed", payload)
    end
  end
end
