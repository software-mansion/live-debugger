defmodule LiveDebugger.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use LiveDebuggerWeb, :component

  @doc """
  Renders an alert with
  """
  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "danger", "success", "warning", "info", "gray"]
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the alert.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div
      class={[
        "bg-#{@color}-100 border border-#{@color}-400 text-#{@color}-700 px-4 py-3 rounded-lg"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
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

  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <div
      class={
        [
          "w-max h-max p-1 border-2 rounded-lg cursor-pointer hover:shadow",
          button_color_classes(@color)
        ] ++
          List.wrap(@class)
      }
      role="button"
      {@rest}
    >
      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
    </h1>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h2(assigns) do
    ~H"""
    <h2 class={["text-2xl font-extrabold leading-10 sm:text-3xl" | List.wrap(@class)]} {@rest}>
      {render_slot(@inner_block)}
    </h2>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h3(assigns) do
    ~H"""
    <h3 class={["text-xl font-bold leading-7 sm:text-2xl" | List.wrap(@class)]} {@rest}>
      {render_slot(@inner_block)}
    </h3>
    """
  end

  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h4(assigns) do
    ~H"""
    <h4 class={["text-lg font-bold leading-6" | List.wrap(@class)]} {@rest}>
      {render_slot(@inner_block)}
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
      {render_slot(@inner_block)}
    </h5>
    """
  end

  @doc """
  Renders a [Heroicon](https://heroicons.com).
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

  attr(:class, :any, default: nil, doc: "Additional classes to add to the spinner.")
  attr(:size, :string, default: "md", values: ["xs", "sm", "md", "lg", "xl"])
  attr(:rest, :global)

  def spinner(assigns) do
    ~H"""
    <span class={["flex" | List.wrap(@class)]} {@rest}></span>
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
      {render_slot(@inner_block)}
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
      <.link class="text-gray-600 underline" navigate={live_debugger_base_url(@socket)}>
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

  defp button_color_classes(color) do
    case color do
      "white" ->
        "bg-white hover:bg-gray-300 border-white hover:border-gray-300 text-black hover:text-black"

      "gray" ->
        "bg-gray-500 hover:bg-gray-800 border-gray-500 hover:border-gray-800 text-black hover:text-white"

      _ ->
        "bg-#{color}-500 hover:bg-#{color}-800 border-#{color}-500 hover:border-#{color}-800 text-white"
    end
  end
end
