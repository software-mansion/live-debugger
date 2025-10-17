defmodule LiveDebuggerDev.LiveViews.Simple do
  @moduledoc false
  use DevWeb, :live_view

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)

  def live_render(assigns) do
    assigns = assign(assigns, session: %{"id" => assigns.id})

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session) %>
    """
  end

  def mount(_params, session, socket) do
    socket
    |> assign(id: session["id"])
    |> ok()
  end

  attr(:id, :string, required: true)

  def render(assigns) do
    ~H"""
    <.box title="Simple [LiveView]" color="yellow">
      <.live_component id={"#{@id}_conditional"} module={LiveDebuggerDev.LiveComponents.Conditional}>
        <.live_component
          id={"#{@id}_conditional_many_assigns"}
          module={LiveDebuggerDev.LiveComponents.ManyAssigns}
        />
      </.live_component>
    </.box>
    """
  end
end
