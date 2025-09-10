defmodule LiveDebuggerDev.LiveViews.EndlessCrashReload do
  use DevWeb, :live_view

  alias Phoenix.LiveView.AsyncResult

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:loop, AsyncResult.loading())
      |> start_async(:loop, fn ->
        raise "crash"
      end)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={_loop} assign={@loop}>
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
