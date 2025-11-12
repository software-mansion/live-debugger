defmodule LiveDebuggerDev.LiveViews.StatelessExample do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :id, "0")}
  end

  def render(assigns) do
    dbg("render")
    ~H"""
    <.box id={@id} title="Stateless Example [LiveView]" color="teal">
      <div class="space-y-4">
        <.box1 id={@id <> "1"} />
        <.box1 id={@id <> "2"} show_box2={true} />
      </div>
    </.box>
    """
  end

  attr(:id, :string, required: true)
  attr(:show_box2, :boolean, default: false)

  defp box1(assigns) do
    dbg("box1")
    ~H"""
    <.box id={@id} title="Box1 [Function Component]" color="blue">
      This is a stateless function component (Box1)
      <%= if @show_box2 do %>
        <.box2 id={@id <> "1"} />
      <% end %>
    </.box>
    """
  end

  attr(:id, :string, required: true)

  defp box2(assigns) do
    dbg("box2")
    ~H"""
    <.box id={@id} title="Box2 [Function Component]" color="green">
      This is a stateless function component (Box2) rendered inside Box1
    </.box>
    """
  end
end
