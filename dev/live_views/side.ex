defmodule LiveDebuggerDev.LiveViews.Side do
  @moduledoc false
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
    <.box title="Side [LiveView]" color="green">
      <div></div>
    </.box>
    """
  end

  def handle_info(:hello, socket) do
    {:noreply, socket}
  end
end
