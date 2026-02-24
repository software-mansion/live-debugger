defmodule LiveDebuggerDev.LiveViews.Nested do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveViews

  def mount(_params, session, socket) do
    socket
    |> assign(id: session["id"] || "nested")
    |> ok()
  end

  def render(assigns) do
    ~H"""
    <.box title="Nested Live Views [LiveView]" color="blue">
      <LiveViews.Simple.live_render socket={@socket} id={@id <> "_inner"} />
      <LiveViews.Simple.live_render socket={@socket} id={@id <> "_inner2"} />
    </.box>
    """
  end
end
