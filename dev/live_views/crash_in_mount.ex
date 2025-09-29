defmodule LiveDebuggerDev.LiveViews.CrashInMount do
  use DevWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:some_value, AsyncResult.loading())

    if connected?(socket) do
      # Simulating expensive work
      Process.sleep(2000)

      raise "Crash in mount"
    end

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={_value} assign={@some_value}>
      <:loading>
        <p class="font-semibold animate-pulse">Loading...</p>
      </:loading>
      <:failed>
        <p class="font-semibold">There was an error loading the page</p>
      </:failed>
    </.async_result>
    """
  end
end
