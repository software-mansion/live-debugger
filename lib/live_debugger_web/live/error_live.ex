defmodule LiveDebuggerWeb.ErrorLive do
  use LiveDebuggerWeb, :live_view

  @impl true
  def mount(%{"error" => error}, _, socket) do
    socket
    |> assign(error: error)
    |> assign_heading()
    |> assign_description()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8 text-center">
      <.icon name="icon-exclamation-circle" class="w-12 h-12 text-error-icon" />
      <div class="font-semibold text-xl mb-2">
        <%= @heading %>
      </div>
      <p class="mb-4"><%= @description %></p>
      <.link navigate={LiveDebuggerWeb.Helpers.RoutesHelper.live_views_dashboard()}>
        <.button>
          See active LiveViews
        </.button>
      </.link>
    </div>
    """
  end

  defp assign_heading(%{assigns: %{error: "not_found"}} = socket) do
    assign(socket, heading: "Debugger disconnected")
  end

  defp assign_heading(%{assigns: %{error: "invalid_pid"}} = socket) do
    assign(socket, heading: "Invalid PID format")
  end

  defp assign_heading(socket) do
    assign(socket, heading: "Unexpected error")
  end

  defp assign_description(%{assigns: %{error: "not_found"}} = socket) do
    assign(socket, description: "We couldn't find any LiveView associated with the given pid")
  end

  defp assign_description(%{assigns: %{error: "invalid_pid"}} = socket) do
    assign(socket, description: "PID provided in the URL has invalid format")
  end

  defp assign_description(socket) do
    assign(socket,
      description: "Debugger encountered unexpected error. Check logs for more information"
    )
  end
end
