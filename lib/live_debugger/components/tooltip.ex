defmodule LiveDebugger.Components.Tooltip do
  use LiveDebuggerWeb, :component

  @doc """
  Render a tooltip using Tooltip hook.
  """
  attr(:content, :string, default: nil)
  attr(:position, :string, default: "bottom", values: ["top", "bottom"])
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    assigns = assign(assigns, :id, "tooltip_" <> Ecto.UUID.generate())

    ~H"""
    <div id={@id} phx-hook="Tooltip" data-tooltip={@content} data-position={@position} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end
end
