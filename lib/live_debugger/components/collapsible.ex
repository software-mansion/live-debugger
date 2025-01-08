defmodule LiveDebugger.Components.Collapsible do
  @moduledoc """
  A collapsible component inspired by the PetalComponents Accordion component.
  """

  use LiveDebuggerWeb, :component

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:chevron_class, :string, default: nil, doc: "CSS class for the chevron icon")
  attr(:open, :boolean, default: false, doc: "Whether the collapsible is open by default")
  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def collapsible(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest} x-data={"{ expanded: #{@open} }"}>
      <div data-open={if @open, do: "true", else: "false"}>
        <div id={content_panel_header_id(@id)} class="flex items-center gap-1">
          <.icon_button open={@open} id={@id} chevron_class={@chevron_class} />
          {render_slot(@label)}
        </div>
        <.content_container id={@id}>
          {render_slot(@inner_block)}
        </.content_container>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:chevron_class, :string, required: true)
  attr(:open, :boolean, required: true)

  defp icon_button(assigns) do
    ~H"""
    <button
      type="button"
      x-on:click="expanded = !expanded"
      aria-expanded="expanded"
      aria-controls={content_panel_id(@id)}
    >
      <.icon
        name="hero-chevron-down-solid"
        class={[@chevron_class, if(@open, do: "rotate-180")]}
        {%{":class": "{'rotate-180': expanded}"}}
      />
    </button>
    """
  end

  attr(:id, :string, required: true)
  slot(:inner_block)

  defp content_container(assigns) do
    ~H"""
    <div
      id={content_panel_id(@id)}
      role="region"
      aria-labelledby={content_panel_header_id(@id)}
      x-show="expanded"
      x-cloak={true}
      x-collapse={true}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  defp content_panel_header_id(id), do: "collapsible-header-#{id}"
  defp content_panel_id(id), do: "collapsible-content-panel-#{id}"
end
