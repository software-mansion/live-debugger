defmodule LiveDebuggerDev.LiveViews.Side do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    current_pid = self()

    Task.start(fn ->
      for _ <- 1..100_000 do
        Process.sleep(8)
        send(current_pid, :hello)
      end
    end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.link navigate="/" class="text-blue-500 underline">Back to main</.link>
    </div>
    """
  end

  def handle_info(:hello, socket) do
    {:noreply, socket}
  end
end
