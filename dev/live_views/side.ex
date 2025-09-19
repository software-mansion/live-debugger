defmodule LiveDebuggerDev.LiveViews.Side do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    current_pid = self()

    Task.start(fn ->
      for i <- 1..100_000 do
        Process.sleep(8)
        send(current_pid, :hello)

        if rem(i, 100) == 0 do
          send(current_pid, :increment)
        end
      end
    end)

    {:ok, assign(socket, counter: 0)}
  end

  def render(assigns) do
    ~H"""
    <.box title="Side [LiveView]" color="green">
      <div></div>
    </.box>
    """
  end

  def handle_info(:hello, socket) do
    {:noreply, socket}
  end

  def handle_info(:increment, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end
end
