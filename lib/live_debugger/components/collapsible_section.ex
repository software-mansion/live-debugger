defmodule LiveDebugger.Components.CollapsibleSection do
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
          <.h3 class="text-primary" no_margin={true}>{@title}</.h3>
        </div>
        {render_slot(@right_panel)}
      </div>
      <div class={[
        "flex h-full overflow-y-auto overflow-x-hidden rounded-md bg-white opacity-90 text-black p-2",
        if(@hide?, do: "hidden lg:flex")
      ]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end
end
