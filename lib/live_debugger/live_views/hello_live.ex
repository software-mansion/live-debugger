defmodule LiveDebugger.LiveViews.HelloLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, :current_pid, inspect(self()))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.container max_width="full" class="mt-5 flex justify-center">
      <.card>
        <.h1 class="m-2">Hello, from {@current_pid}</.h1>
      </.card>
    </.container>
    """
  end
end
