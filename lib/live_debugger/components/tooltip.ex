defmodule LiveDebugger.Components.Tooltip do
  @moduledoc """
  Tooltip component copied from from https://github.com/bluzky/salad_ui
  """
  use LiveDebuggerWeb, :component

  @doc """
  Render a tooltip

  ## Examples:

  <.tooltip>
    <.button variant="outline">Hover me</.button>
    <.tooltip_content class="bg-primary text-white" theme={nil}>
     <p>Hi! I'm a tooltip.</p>
    </.tooltip_content>
  </.tooltip>

  """
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div
      class={[
        "relative group/tooltip inline-block",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  Render
  """
  attr(:class, :string, default: nil)
  attr(:side, :string, default: "top", values: ~w(bottom left right top))
  attr(:align, :string, default: "center", values: ~w(start center end))
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip_content(assigns) do
    assigns =
      assign(assigns, :variant_class, side_variant(assigns.side, assigns.align))

    ~H"""
    <div
      data-side={@side}
      class={[
        "tooltip-content absolute whitespace-nowrap hidden group-hover/tooltip:block",
        "z-50 w-auto overflow-hidden rounded-md border bg-popover px-3 py-1.5 text-sm text-popover-foreground shadow-md animate-in fade-in-0 zoom-in-95 data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2 data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
        @variant_class,
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @variants %{
    side: %{
      "top" => "bottom-full mb-2",
      "bottom" => "top-full mt-2",
      "left" => "right-full mr-2",
      "right" => "left-full ml-2"
    },
    align: %{
      "start-horizontal" => "left-0",
      "center-horizontal" => "left-1/2 -translate-x-1/2 slide-in-from-left-1/2",
      "end-horizontal" => "right-0",
      "start-vertical" => "top-0",
      "center-vertical" => "top-1/2 -translate-y-1/2 slide-in-from-top-1/2",
      "end-vertical" => "bottom-0"
    }
  }

  defp side_variant(side, align) do
    Enum.map_join(%{side: side, align: align(align, side)}, " ", fn {key, value} ->
      @variants[key][value]
    end)
  end

  defp align(align, side) do
    cond do
      side in ["top", "bottom"] ->
        "#{align}-horizontal"

      side in ["left", "right"] ->
        "#{align}-vertical"
    end
  end
end
