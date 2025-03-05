defmodule LiveDebuggerDev.LiveViews.Side do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    current_pid = self()

    Task.start(fn ->
      for _ <- 1..100_000 do
        Process.sleep(10)
        send(current_pid, :hello)
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

  def handle_info(:hello, socket) do
    {:noreply, socket}
  end
end
