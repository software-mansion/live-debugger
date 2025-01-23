defmodule LiveDebugger.Components.Collapsible do
  @moduledoc false

  use LiveDebuggerWeb, :component

  @doc """
  Collapsible section, it throws a toggle-visibility event when the user clicks on the title.
  Payload of toggle visibility event:
    %{"section" => id_passed_in_assigns}
  """
  attr(:id, :string, required: true)
  attr(:myself, :any, required: true)
  attr(:title, :string, default: nil)
  attr(:class, :string, default: "")
  attr(:hide?, :boolean, default: false)

  slot(:right_panel)
  slot(:inner_block)

  def section(assigns) do
    ~H"""
    <div class={[
      "flex flex-col p-4",
      @class
    ]}>
      <div class="flex justify-between">
        <div class="flex gap-2 items-center">
          <.icon
            phx-click="toggle-visibility"
            phx-value-section={@id}
            phx-target={@myself}
            name="hero-chevron-down-solid"
            class={[
              "text-primary lg:hidden cursor-pointer",
              if(@hide?, do: "transform rotate-180")
            ]}
          />
          <.h3 class="text-primary"><%= @title %></.h3>
        </div>
        <%= render_slot(@right_panel) %>
      </div>
      <div class={[
        "flex h-full overflow-y-auto overflow-x-hidden rounded-md bg-white opacity-90 text-black p-2",
        if(@hide?, do: "hidden lg:flex")
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:chevron_class, :string, default: nil, doc: "CSS class for the chevron icon")
  attr(:icon, :string, default: "hero-chevron-down-solid", doc: "Icon name")
  attr(:open, :boolean, default: false, doc: "Whether the collapsible is open by default")
  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def collapsible(assigns) do
    ~H"""
    <div id={@id} class={@class} {@rest} x-data={"{ expanded: #{@open} }"}>
      <div data-open={if @open, do: "true", else: "false"}>
        <div id={content_panel_header_id(@id)} class="flex items-center gap-1">
          <.custom_icon_button open={@open} id={@id} icon={@icon} chevron_class={@chevron_class} />
          <%= render_slot(@label) %>
        </div>
        <.content_container id={@id}>
          <%= render_slot(@inner_block) %>
        </.content_container>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:chevron_class, :string, required: true)
  attr(:icon, :string, required: true)
  attr(:open, :boolean, required: true)

  defp custom_icon_button(assigns) do
    ~H"""
    <button
      type="button"
      x-on:click="expanded = !expanded"
      aria-expanded="expanded"
      aria-controls={content_panel_id(@id)}
    >
      <.icon
        name={@icon}
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
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp content_panel_header_id(id), do: "collapsible-header-#{id}"
  defp content_panel_id(id), do: "collapsible-content-panel-#{id}"
end
