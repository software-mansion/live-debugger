defmodule LiveDebuggerDev.Components do
  use Phoenix.Component

  @routes [
    {"/", "Main"},
    {"/side", "Side"},
    {"/nested", "Nested"},
    {"/messages", "Messages"},
    {"/embedded", "Embedded"},
    {"/embedded_in_controller", "EmbeddedInController"},
    {"/endless_crash_reload", "EndlessCrashReload"},
    {"/stream", "Stream"},
    {"/async_demo", "AsyncDemo"}
  ]

  attr(:routes, :list, default: @routes)

  def navbar(assigns) do
    ~H"""
    <nav class="flex p-4 text-lg w-max gap-4 border-2 border-blue-500 rounded-xl">
      <.link
        :for={{link, name} <- @routes}
        navigate={link}
        class="text-blue-500 hover:text-blue-900 hover:underline"
      >
        <%= name %>
      </.link>
    </nav>
    """
  end

  attr(:id, :string, default: nil)
  attr(:title, :string, required: true)
  attr(:color, :string, default: "blue")
  attr(:class, :string, default: "")

  slot(:inner_block, required: true)

  def box(assigns) do
    ~H"""
    <div id={@id}>
      <span class={"text-sm #{text_color(@color)}"}><%= @title %></span>
      <div class={"border-2 #{border_color(@color)} rounded-md p-8 #{@class}"}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  attr(:color, :string, default: "green")
  attr(:rest, :global)

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button class={"#{background_color(@color)} text-white py-1 px-2 rounded"} {@rest}>
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  defp text_color("blue"), do: "text-blue-500"
  defp text_color("red"), do: "text-red-500"
  defp text_color("green"), do: "text-green-500"
  defp text_color("purple"), do: "text-purple-500"
  defp text_color("gray"), do: "text-gray-500"
  defp text_color("teal"), do: "text-teal-500"
  defp text_color("orange"), do: "text-orange-500"
  defp text_color("yellow"), do: "text-yellow-500"

  defp border_color("blue"), do: "border-blue-500"
  defp border_color("red"), do: "border-red-500"
  defp border_color("green"), do: "border-green-500"
  defp border_color("purple"), do: "border-purple-500"
  defp border_color("gray"), do: "border-gray-500"
  defp border_color("teal"), do: "border-teal-500"
  defp border_color("orange"), do: "border-orange-500"
  defp border_color("yellow"), do: "border-yellow-500"

  defp background_color("blue"), do: "bg-blue-500"
  defp background_color("red"), do: "bg-red-500"
  defp background_color("green"), do: "bg-green-500"
  defp background_color("purple"), do: "bg-purple-500"
  defp background_color("gray"), do: "bg-gray-500"
  defp background_color("teal"), do: "bg-teal-500"
  defp background_color("orange"), do: "bg-orange-500"
  defp background_color("yellow"), do: "bg-yellow-500"
end
