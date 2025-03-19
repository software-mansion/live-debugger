defmodule LiveDebuggerDev.LiveViews.Messages do
  use DevWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.navbar />
      <.box title="Messages [LiveView]" color="purple">
        <div>
          <.button phx-click="big-message" color="purple">Send big message</.button>
        </div>
      </.box>
    </div>
    """
  end

  def handle_event("big-message", _, socket) do
    send(self(), very_big_message())
    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
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
