defmodule LiveDebuggerDev.LiveViews.Messages do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :message, nil)}
  end

  def render(assigns) do
    ~H"""
    <.box title="Messages [LiveView]" color="purple">
      <div>
        <.button phx-click="big-message" color="purple">Send big message</.button>
        <p>Big message:</p>
        <pre><%= inspect(@message) %></pre>
      </div>
    </.box>
    """
  end

  def handle_event("big-message", _, socket) do
    if socket.assigns.message do
      send(self(), nil)
    else
      send(self(), very_big_message())
    end

    {:noreply, socket}
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
