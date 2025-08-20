defmodule LiveDebugger.App.Web.ErrorLive do
  @moduledoc false

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

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
      <.link navigate={RoutesHelper.discovery()}>
        <.button>
          See active LiveViews
        </.button>
      </.link>
    </div>
    """
  end

  defp assign_heading(socket) do
    heading =
      case socket.assigns.error do
        "invalid_pid" -> "Invalid PID format"
        "invalid_node_id" -> "Invalid node id"
        _ -> "Unexpected error"
      end

    assign(socket, heading: heading)
  end

  defp assign_description(socket) do
    description =
      case socket.assigns.error do
        "invalid_pid" ->
          "PID provided in the URL has invalid format"

        "invalid_node_id" ->
          "Node id provided in the URL has invalid format"

        _ ->
          "Debugger encountered unexpected error. Check logs for more information"
      end

    assign(socket, description: description)
  end
end
