defmodule LiveDebuggerDev.LiveViews.Side do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    current_pid = self()

    Task.start(fn ->
      for _ <- 1..100_000 do
        Process.sleep(8)
        send(current_pid, very_big_message())
      end
    end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.navbar />
      <.box title="Side [LiveView]" color="green">
        <div></div>
      </.box>
    </div>
    """
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

    Enum.reduce(1..100, %{}, fn i, acc ->
      Map.put(acc, i, part)
    end)
  end
end
