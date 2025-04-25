defmodule LiveDebugger.LiveComponents.SendEventForm do
  @moduledoc false

  use LiveDebuggerWeb, :live_component

  @impl true
  def update(%{lv_process: lv_process}, socket) do
    %{socket: debugged_socket} = :sys.get_state(lv_process.pid)

    debugged_socket =
      attach_hook(debugged_socket, :live_debugger_hook, :handle_info, fn
        {:live_debugger_event, update_function}, socket ->
          socket = update_function.(socket)
          {:halt, socket}

        _, socket ->
          {:cont, socket}
      end)

    :sys.replace_state(lv_process.pid, fn state ->
      %{state | socket: debugged_socket}
    end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <button phx-click="increment">Increment</button>
    </div>
    """
  end

  @impl true
  def handle_event("increment", _unsigned_params, socket) do
    # This will come from params - client is choosing which handler wants to be called
    module = socket.assigns.lv_process.module
    function = :handle_event

    send(
      socket.assigns.lv_process.pid,
      {:live_debugger_event,
       fn socket ->
         {_, socket} = apply(module, function, ["increment", %{}, socket])
         socket
       end}
    )

    {:noreply, socket}
  end
end
