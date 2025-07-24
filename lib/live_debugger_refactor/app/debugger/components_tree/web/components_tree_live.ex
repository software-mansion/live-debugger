defmodule LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web.ComponentsTreeLive do
  @moduledoc """
  Nested LiveView component that displays a tree of LiveView and LiveComponent nodes.
  """

  use LiveDebuggerRefactor.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.App.Debugger.ComponentsTree.Web.Components

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(:tree, AsyncResult.loading())
    |> assign(:highlight?, false)
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner size="sm" /></div>
      </:loading>
      <:failed :let={_error}>
        <.alert>Couldn't load a tree</.alert>
      </:failed>
      <div class="min-h-20 px-1 overflow-y-auto overflow-x-hidden flex flex-col">
        <div class="flex items-center justify-between">
          <div class="shrink-0 font-medium text-secondary-text px-6 py-3">Components Tree</div>
          <.toggle_switch
            :if={LiveDebuggerRefactor.Feature.enabled?(:highlighting)}
            id="highlight-switch"
            label="Highlight"
            checked={@highlight?}
            phx-click="toggle-highlight"
          />
        </div>
        <div class="flex-1">
          <Components.tree_node
            id="components-tree"
            tree_node={tree}
            selected_node_id={@selected_node_id}
            max_opened_node_level={@max_opened_node_level}
          />
        </div>
      </div>
    </.async_result>
    """
  end

  @impl true
  def handle_event("toggle-highlight", _params, socket) do
    socket
    |> update(:highlight?, &(not &1))
    |> noreply()
  end

  def handle_event("select_node", _, socket) do
    socket
    |> noreply()
  end
end
