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
    <div id={@id} class={@class} {@rest} {js_attributes("container", @id, @open)}>
      <div {js_attributes("item", @id, @open)} data-open={if @open, do: "true", else: "false"}>
        <div id={content_panel_header_id(@id)} class="flex items-center gap-1">
          <button type="button" {js_attributes("button", @id, @open)}>
            <.icon
              name="hero-chevron-down-solid"
              class={[@chevron_class, if(@open, do: "rotate-180")]}
              {js_attributes("icon", @id, @open)}
            />
          </button>
          {render_slot(@label)}
        </div>
        <div {js_attributes("content_container", @id, @open)}>
          {render_slot(@inner_block)}
        </div>
      </div>
    </div>
    """
  end

  defp js_attributes("container", _id, open), do: %{"x-data": "{ expanded: #{open} }"}
  defp js_attributes("item", _id, _open), do: %{}

  defp js_attributes("button", id, _open) do
    %{
      "x-on:click": "expanded = !expanded",
      ":aria-expanded": "expanded",
      "aria-controls": content_panel_id(id)
    }
  end

  defp js_attributes("content_container", id, _open) do
    %{
      id: content_panel_id(id),
      role: "region",
      "aria-labelledby": content_panel_header_id(id),
      "x-show": "expanded",
      "x-cloak": true,
      "x-collapse": true
    }
  end

  defp js_attributes("icon", _id, _open), do: %{":class": "{ 'rotate-180': expanded }"}
  defp js_attributes(_type, _id, _open), do: %{}

  defp content_panel_header_id(id), do: "collapsible-header-#{id}"
  defp content_panel_id(id), do: "collapsible-content-panel-#{id}"
end
