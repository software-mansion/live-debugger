defmodule LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsDisplay do
  @moduledoc """
  LiveComponent that can be used to display a tree of terms.
  It removes children of collapsed nodes from HTML, and adds them when the node is opened.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser.TermNode
  alias LiveDebugger.App.Utils.TermParser
  alias Phoenix.LiveView.AsyncResult

  @required_assigns [:node_assigns_info]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:assigns_display, :handle_event, &handle_event/3)
    |> register_hook(:assigns_display)
  end

  attr(:id, :string, required: true)
  attr(:node, TermNode, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id}>
      <.term node={@node} />
    </div>
    """
  end

  defp handle_event("toggle_node", %{"id" => id}, socket) do
    node_assigns_info =
      with %AsyncResult{ok?: true, result: {node_assigns, term_node, copy_string}} <-
             socket.assigns.node_assigns_info,
           {:ok, updated_term_node} <-
             TermParser.update_by_id(term_node, id, fn node ->
               {:ok, %TermNode{node | open?: !node.open?}}
             end) do
        AsyncResult.ok({node_assigns, updated_term_node, copy_string})
      else
        {:error, reason} ->
          AsyncResult.failed(socket.assigns.node_assigns_info, reason)

        _ ->
          socket.assigns.node_assigns_info
      end

    socket
    |> assign(:node_assigns_info, node_assigns_info)
    |> halt()
  end

  defp handle_event("toggle_node", _, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}

  attr(:node, TermNode, required: true)

  defp term(assigns) do
    assigns =
      assigns
      |> assign(:has_children?, TermNode.has_children?(assigns.node))

    ~H"""
    <div class="font-code" phx-click="toggle_node" phx-value-id={@node.id}>
      <%= if @has_children? do %>
        <.static_collapsible
          open={@node.open?}
          label_class="max-w-max"
          chevron_class="text-code-2 m-auto w-[2ch] h-[2ch]"
          phx-click="toggle_node"
          phx-value-id={@node.id}
        >
          <:label :let={open}>
            <%= if open do %>
              <ElixirDisplay.text_items items={@node.expanded_before} />
            <% else %>
              <ElixirDisplay.text_items items={@node.content} />
            <% end %>
          </:label>
          <ol class="m-0 ml-[2ch] block list-none p-0">
            <li :for={{_, child} <- @node.children} class="flex flex-col">
              <.term node={child} />
            </li>
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
end
