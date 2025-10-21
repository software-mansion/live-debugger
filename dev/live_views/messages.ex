defmodule LiveDebuggerDev.LiveViews.Messages do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    socket
    |> assign(:messages, [])
    |> ok()
  end

  attr(:messages, :list, required: true)

  def render(assigns) do
    ~H"""
    <.box title="Messages [LiveView]" color="purple">
      <div>
        <.button phx-click="big-message" color="purple">Send big message</.button>
        <div>Message count: <%= length(@messages) %></div>
      </div>
    </.box>
    """
  end

  def handle_event("big-message", _, socket) do
    send(self(), very_big_message())

    socket
    |> assign(:messages, [
      {length(socket.assigns.messages), very_big_message()} | socket.assigns.messages
    ])
    |> noreply()
  end

  def handle_info(message, socket) do
    {:noreply, assign(socket, :message, message)}
  end

  defp very_big_message() do
    part = %{
      list: [1, 2, 3, 4],
      map: %{a: 1, b: 2},
      keyword: [a: 1, b: 2],
      tuple: {1, 2},
      string: "string",
      atom: :some_atom,
      number: 42.12,
      boolean: true,
      nil: nil,
      pid: self()
    }

    Enum.reduce(1..1000, %{}, fn i, acc ->
      Map.put(acc, i, part)
    end)
  end
end
