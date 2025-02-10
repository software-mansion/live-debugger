defmodule LiveDebugger.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use Phoenix.Component

  @doc """
  Renders an alert with
  """
  attr(:variant, :string,
    required: true,
    values: ["danger", "success", "warning", "info"]
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the alert.")
  attr(:with_icon, :boolean, default: false, doc: "Whether to show an icon.")
  attr(:heading, :string, default: nil, doc: "Heading for the alert.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div
      class={[
        "bg-#{@variant}-100 border border-#{@variant}-400 text-#{@variant}-700 p-2 flex flex-col gap-1 text-sm rounded-lg"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <div class="flex items-center gap-2">
        <.alert_icon :if={@with_icon} variant={@variant} />
        <.h5 class="font-bold">{@heading}</.h5>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a button.

  """
  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "danger", "success", "warning", "info", "gray", "white"]
  )

  attr(:variant, :string, default: "solid", values: ["solid", "simple"])
  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <div
      class={
        [
          "w-max h-max p-1 cursor-pointer",
          if(@variant != "simple", do: "border-2 rounded-lg hover:shadow"),
          button_color_classes(@color, @variant)
        ] ++
          List.wrap(@class)
      }
      role="button"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a card.
  """
  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "danger", "success", "warning", "info", "gray"]
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the card.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div
      class={["border-2 border-#{@color}-600 shadow-2xl p-2 rounded-lg" | List.wrap(@class)]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Typography component to render headings.
  """

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h1(assigns) do
    ~H"""
    <h1
      class={[
        "text-4xl font-extrabold leading-10 sm:text-5xl sm:tracking-tight lg:text-6xl"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h2(assigns) do
    ~H"""
    <h2 class={["text-2xl font-extrabold leading-10 sm:text-3xl" | List.wrap(@class)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </h2>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h3(assigns) do
    ~H"""
    <h3 class={["text-xl font-bold leading-7 sm:text-2xl" | List.wrap(@class)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </h3>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h4(assigns) do
    ~H"""
    <h4 class={["text-lg font-bold leading-6" | List.wrap(@class)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </h4>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h5(assigns) do
    ~H"""
    <h5
      class={[
        "text-lg font-medium leading-6"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </h5>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).
  Not all icons are available. If you want to use an icon check if it exists in the `assets/icons` folder.
  ## Examples

      <.icon name="hero-x-mark-solid" />
  """
  attr(:name, :string, required: true, doc: "The name of the icon. Must start with `hero-`.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the icon.")
  attr(:rest, :global)

  def icon(%{name: "hero-" <> _} = assigns) do
    ~H"""
    <span class={[@name, List.wrap(@class)]} {@rest}></span>
    """
  end

  @doc """
  Renders a fullscreen using Fullscreen hook.
  If you want to open fullscreen from a button, you can use `phx-hook="OpenFullscreen"` and `data-fullscreen-id` attributes.
  You can close the fullscreen using X button or by pressing ESC key.
  """
  attr(:id, :string, required: true)

  attr(:class, :any,
    default: nil,
    doc: "Additional classes to be added to the fullscreen element."
  )

  slot(:inner_block, required: true)

  def fullscreen(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Fullscreen"
      class={[
        "relative w-full h-full p-2 overflow-auto hidden flex-col rounded-lg backdrop:bg-black backdrop:opacity-50"
        | List.wrap(@class)
      ]}
    >
      <div class="flex justify-end items-center h-max w-full">
        <.button
          id={"#{@id}-close"}
          phx-hook="CloseFullscreen"
          data-fullscreen-id={@id}
          variant="simple"
          class="hover:bg-primary-500 hover:bg-opacity-10 rounded-full"
        >
          <.icon name="hero-x-mark-solid" class="h-7 w-7" />
        </.button>
      </div>
      <div class="w-full h-full overflow-auto flex flex-col gap-2">
        <%= render_slot(@inner_block) %>
      </div>
    </dialog>
    """
  end

  @doc """
  Renders a button which will show a fullscreen when clicked.
  Content of the fullscreen is passed as `:inner_block` slot.

  ## Examples

      <.fullscreen_wrapper id="my_fullscreen">
        <.h1>Hello World</.h1>
      </.fullscreen_wrapper>
  """
  attr(:id, :string, required: true)

  attr(:fullscreen_class, :any,
    default: nil,
    doc: "Additional classes to be added to the fullscreen."
  )

  attr(:class, :any, default: nil, doc: "Additional classes to be added to the button.")

  attr(:icon, :string,
    default: "hero-arrow-top-right-on-square",
    doc: "Icon to be displayed as a button"
  )

  slot(:inner_block, required: true)

  def fullscreen_wrapper(assigns) do
    ~H"""
    <div>
      <.button
        id={"fullscreen_#{@id}_button"}
        phx-hook="OpenFullscreen"
        data-fullscreen-id={"fullscreen_#{@id}"}
        class={["flex items-center justify-center w-max h-max" | List.wrap(@class)]}
        variant="simple"
      >
        <.icon name={@icon} class="w-5 h-5" />
      </.button>
      <.fullscreen id={"fullscreen_#{@id}"} class={@fullscreen_class}>
        <%= render_slot(@inner_block) %>
      </.fullscreen>
    </div>
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")

  attr(:size, :string,
    default: "md",
    values: ["xs", "sm", "md", "lg", "xl"],
    doc: "Size of the spinner"
  )

  attr(:show, :boolean, default: true, doc: "show or hide spinner")
  attr(:rest, :global)

  def spinner(assigns) do
    size_class =
      case assigns.size do
        "xs" -> "h-4 w-4"
        "sm" -> "h-6 w-6"
        "md" -> "h-8 w-8"
        "lg" -> "h-10 w-10"
        "xl" -> "h-12 w-12"
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg
      {@rest}
      class={
        ["animate-spin text-primary", @size_class, unless(@show, do: "hidden")] ++
          List.wrap(@class)
      }
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-10" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="none"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  @doc """
  Renders a tooltip using Tooltip hook.
  """
  attr(:id, :string, required: true)
  attr(:content, :string, default: nil)
  attr(:position, :string, default: "bottom", values: ["top", "bottom"])
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div
      id={"tooltip_" <> @id}
      phx-hook="Tooltip"
      data-tooltip={@content}
      data-position={@position}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:socket, :any, required: true)

  def not_found_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Debugger disconnected</.h2>
      <.h5 class="text-center">
        We couldn't find any LiveView associated with the given socket id
      </.h5>
      <.link class="text-gray-600 underline" navigate="/">
        See available LiveSessions
      </.link>
    </div>
    """
  end

  def error_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Unexpected error</.h2>
      <.h5 class="text-center">
        Debugger encountered unexpected error - check logs for more
      </.h5>
      <span>You can close this window</span>
    </div>
    """
  end

  def session_limit_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8">
      <.icon name="hero-exclamation-circle" class="w-16 h-16" />
      <.h2 class="text-center">Session limit reached</.h2>
      <.h5 class="text-center">
        In OTP 26 and older versions you can open only one debugger window.
      </.h5>
      <span>You can close this window</span>
    </div>
    """
  end

  attr(:variant, :string, required: true, values: ["danger", "success", "warning", "info"])

  defp alert_icon(assigns) do
    icon_name =
      case assigns.variant do
        "danger" -> "hero-x-circle"
        "success" -> "hero-check-circle"
        "warning" -> "hero-exclamation-circle"
        "info" -> "hero-information-circle"
      end

    assigns = assign(assigns, :name, icon_name)

    ~H"""
    <.icon name={@name} class="text-{@variant}-700" />
    """
  end

  defp button_color_classes(color, "simple") do
    case color do
      "white" ->
        "text-white hover:text-gray-300"

      color ->
        "text-#{color}-500 hover:text-#{color}-900"
    end
  end

  defp button_color_classes(color, "solid") do
    case color do
      "white" ->
        "bg-white hover:bg-gray-300 border-white hover:border-gray-300 text-black hover:text-black"

      "gray" ->
        "bg-gray-500 hover:bg-gray-800 border-gray-500 hover:border-gray-800 text-black hover:text-white"

      color ->
        "bg-#{color}-500 hover:bg-#{color}-800 border-#{color}-500 hover:border-#{color}-800 text-white"
    end
  end
end
