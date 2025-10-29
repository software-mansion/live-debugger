defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.TermNodeToggle do
  @moduledoc """
  Hook that can be used to toggle the open state of a `assigns` term node.
  """

  use LiveDebugger.App.Web, :hook

  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermParser
  alias Phoenix.LiveView.AsyncResult

  @required_assigns [:node_assigns_info]

  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:term_node_toggle, :handle_event, &handle_event/3)
    |> register_hook(:term_node_toggle)
  end

  defp handle_event("toggle_node", %{"id" => id}, socket) do
    node_assigns_info =
      with %AsyncResult{ok?: true, result: {node_assigns, term_node, copy_string}} <-
             socket.assigns.node_assigns_info,
           {:ok, updated_term_node} <-
             TermParser.update_by_id(term_node, id, fn %TermNode{} = node ->
               %TermNode{node | open?: !node.open?}
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
end
