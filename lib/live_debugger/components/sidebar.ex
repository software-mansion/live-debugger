defmodule LiveDebugger.Components.Sidebar do
  use LiveDebuggerWeb, :component

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree

  attr(:socket, :map, required: true)

  def sidebar_label(assigns) do
    ~H"""
    <.link patch="/" class="flex items-center gap-2">
      <.icon class="text-white" name="hero-chevron-left-solid" />
      <.h3 class="text-white">LiveDebugger</.h3>
    </.link>
    """
  end

  attr(:socket_id, :string, required: true)
  attr(:pid, :any, required: true)
  attr(:tree, :any, required: true)
  attr(:node_id, :any, required: true)

  def sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 p-2">
      <.basic_info pid={@pid} socket_id={@socket_id} />
      <.separate_bar />
      <.component_tree tree={@tree} selected_node_id={@node_id} />
    </div>
    """
  end

  slot(:header)
  slot(:inner_block)

  def sidebar_slide_over(assigns) do
    ~H"""
    <div class="absolute z-20 top-0 left-0 w-full h-screen bg-primary text-white p-2">
      <div class="w-full flex justify-between p-2">
        <%= render_slot(@header) %>
        <.sidebar_icon_button icon="hero-x-mark" phx-click="close_mobile_content" />
      </div>
      <.separate_bar />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  defp basic_info(assigns) do
    ~H"""
    <.card class="p-4 flex flex-col gap-1 bg-gray-200 text-black">
      <%= for {text, value} <- [
        {"Monitored socket:", @socket_id},
        {"Debugged PID:", Parsers.pid_to_string(@pid)}
      ] do %>
        <div class="font-semibold text-primary"><%= text %></div>
        <div><%= value %></div>
      <% end %>
    </.card>
    """
  end

  attr(:tree, :any, required: true)
  attr(:selected_node_id, :string, default: nil)

  defp component_tree(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner class="text-white" /></div>
      </:loading>
      <:failed :let={_error}>
        <.alert variant="danger">Couldn't load a tree</.alert>
      </:failed>
      <Tree.tree
        :if={tree}
        title="Components Tree"
        selected_node_id={@selected_node_id}
        tree_node={tree}
        class="bg-gray-200"
      />
    </.async_result>
    """
  end

  attr(:icon, :string, required: true)
  attr(:link, :string, default: nil)
  attr(:rest, :global)

  def sidebar_icon_button(assigns) do
    ~H"""
    <.button color="white" {@rest}>
      <.icon class="text-primary" name={@icon} />
    </.button>
    """
  end

  def separate_bar(assigns) do
    ~H"""
    <div class="border-b h-0 border-white my-4"></div>
    """
  end
end
