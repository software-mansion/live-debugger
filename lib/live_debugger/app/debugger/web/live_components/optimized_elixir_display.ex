defmodule LiveDebugger.App.Debugger.Web.LiveComponents.OptimizedElixirDisplay do
  @moduledoc """
  Optimized ElixirDisplay LiveComponent that can be used to display a tree of terms.
  It removes children of collapsed nodes from HTML, and adds them when the node is opened.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.App.Utils.TermParser.TermNode

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node, assigns.node)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.term id={@id} node={@node} myself={@myself} />
    </div>
    """
  end

  @impl true
  def handle_event("toggle_node", %{"id" => id}, socket) do
    node = update_node_children(socket.assigns.node, id)

    socket
    |> assign(:node, node)
    |> noreply()
  end

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)
  attr(:myself, :any, required: true)

  defp term(assigns) do
    assigns =
      assigns
      |> assign(:has_children?, TermParser.has_children?(assigns.node))

    ~H"""
    <div class="font-code" phx-click="toggle_node" phx-value-id={@node.id} phx-target={@myself}>
      <%= if @has_children? do %>
        <.static_collapsible
          open={@node.open?}
          label_class="max-w-max"
          chevron_class="text-code-2 m-auto w-[2ch] h-[2ch]"
          phx-click="toggle_node"
          phx-value-id={@node.id}
          phx-target={@myself}
        >
          <:label :let={open}>
            <%= if open do %>
              <ElixirDisplay.text_items items={@node.expanded_before} />
            <% else %>
              <ElixirDisplay.text_items items={@node.content} />
            <% end %>
          </:label>
          <ol class="m-0 ml-[2ch] block list-none p-0">
            <%= for {child, index} <- Enum.with_index(@node.children) do %>
              <li class="flex flex-col">
                <.term id={@id <> "-#{index}"} node={child} myself={@myself} />
              </li>
            <% end %>
          </ol>
          <div class="ml-[2ch]">
            <ElixirDisplay.text_items items={@node.expanded_after} />
          </div>
        </.static_collapsible>
      <% else %>
        <div class="ml-[2ch]">
          <ElixirDisplay.text_items items={@node.content} />
        </div>
      <% end %>
    </div>
    """
  end

  defp update_node_children(node, "root"), do: %TermNode{node | open?: !node.open?}

  defp update_node_children(node, id) do
    ["root" | id_path] = id |> String.split(".")

    id_path = Enum.map(id_path, &String.to_integer(&1))

    recursively_update_node_children(node, id_path)
  end

  defp recursively_update_node_children(node, []) when is_struct(node, TermNode) do
    %TermNode{node | open?: !node.open?}
  end

  defp recursively_update_node_children(node, [id | rest]) when is_struct(node, TermNode) do
    child_node =
      node.children
      |> Enum.at(id)
      |> recursively_update_node_children(rest)

    updated_children = List.replace_at(node.children, id, child_node)

    %TermNode{node | children: updated_children}
  end
end
