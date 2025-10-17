defmodule LiveDebuggerDev.LiveComponents.Wrapper do
  @moduledoc false
  use DevWeb, :live_component

  slot(:inner_block)

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Wrapper [LiveComponent]" color="red">
        <%= render_slot(@inner_block) %>
      </.box>
    </div>
    """
  end
end
