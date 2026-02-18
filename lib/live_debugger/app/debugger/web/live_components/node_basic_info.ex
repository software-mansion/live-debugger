defmodule LiveDebugger.App.Debugger.Web.LiveComponents.NodeBasicInfo do
  @moduledoc """
  Basic information about the node.
  """

  use LiveDebugger.App.Web, :live_component

  import LiveDebugger.App.Web.Hooks.Flash, only: [push_flash: 3]
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Debugger.Queries.Node, as: NodeQueries
  alias LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Debugger.Web.Components.Pages
  alias LiveDebugger.App.Debugger.Utils.Editor

  @impl true
  def update(%{:editor_error => editor_error}, socket) do
    socket
    |> push_flash(:error, editor_error)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign(:elixir_editor, Editor.detect_editor())
    |> assign_node_type()
    |> assign_async_node_module()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:lv_process, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id={@id}
      class="w-full min-w-[20rem] h-max max-h-full overflow-y-auto p-4 shrink-0 flex flex-col border border-default-border bg-surface-0-bg rounded-sm"
    >
      <.async_result :let={node_module} assign={@node_module}>
        <:loading>
          <div class="w-full h-30 flex justify-center items-center"><.spinner size="sm" /></div>
        </:loading>
        <:failed>
          <.alert class="w-[15rem]">
            <p>Couldn't load basic information about the node.</p>
          </.alert>
        </:failed>
        <div class="flex flex-row gap-8 max-sm_bi:flex-col max-sm_bi:gap-4 sm_bi:items-center p-3">
          <div class="min-w-0 flex flex-col gap-2">
            <span class="font-medium">Module:</span>
            <div class="flex gap-2 min-w-0">
              <.tooltip
                id={@id <> "-current-node-module"}
                content={node_module.module_name}
                class="truncate"
              >
                <%= node_module.module_name %>
              </.tooltip>
              <.copy_button id="copy-button-module-name" value={node_module.module_name} />
            </div>
          </div>

          <div class="min-w-0 flex flex-col gap-2">
            <span class="font-medium">Path:</span>

            <div class="flex flex-row gap-2">
              <.tooltip
                id={@id <> "-current-node-module-path"}
                content={node_module.module_path <> ":" <> Integer.to_string(node_module.line)}
                class="truncate"
              >
                <%= node_module.module_path <> ":" <> Integer.to_string(node_module.line) %>
              </.tooltip>
              <.copy_button id="copy-button-module-path" value={node_module.module_path} />
            </div>
          </div>

          <div class="shrink-0 flex flex-col gap-2 max-sm_bi:border-b max-sm_bi:border-default-border pb-2">
            <span class="font-medium">Type:</span>
            <span><%= @node_type %></span>
          </div>

          <div class="flex flex-row gap-2 max-sm_ct:flex-col sm_bi:ml-auto">
            <div class="flex flex-row gap-2">
              <.button
                class="shrink-0 sm_bi:ml-auto"
                variant="secondary"
                size="sm"
                id="send-event-button"
                disabled={not @lv_process.alive?}
                phx-click="open-send-event"
                phx-target={@myself}
              >
                <.icon name="icon-send" class="w-4 h-4" /> Send Event
              </.button>

              <div class="flex flex-row items-center gap-2">
                <.button
                  disabled={!@elixir_editor}
                  class="shrink-0"
                  variant="secondary"
                  id="open-in-editor"
                  size="sm"
                  phx-click="open-in-editor"
                  phx-target={@myself}
                  phx-value-file={node_module.module_path}
                  phx-value-line={node_module.line}
                >
                  <.icon name="icon-external-link" class="w-4 h-4" /> Open in Editor
                </.button>

                <.tooltip
                  id={@id <> "-env-not-set"}
                  content="Cannot open in editor? See the documentation."
                >
                  <span :if={!@elixir_editor} class="text-error-text">
                    <.link href="https://example.com/configure-editor" target="_blank">
                      <.icon name="icon-info" class="w-4 h-4" />
                    </.link>
                  </span>
                </.tooltip>
              </div>
            </div>

            <.button
              class="shrink-0 sm_bi:ml-auto md_ct:hidden"
              variant="secondary"
              size="sm"
              id="show-components-tree-button"
              phx-click={Pages.get_open_sidebar_js(:node_inspector)}
            >
              <.icon name="icon-component" class="w-4 h-4" /> Show Components Tree
            </.button>
          </div>
        </div>
      </.async_result>
      <.live_component
        module={SendEventFullscreen}
        id="send-event-fullscreen"
        lv_process={@lv_process}
        node_id={@node_id}
      />
    </div>
    """
  end

  @impl true
  def handle_event("open-send-event", _, socket) do
    socket
    |> push_event("send-event-fullscreen-open", %{})
    |> noreply()
  end

  def handle_event("open-in-editor", %{"file" => file, "line" => line}, socket) do
    cmd = Editor.get_editor_cmd(socket.assigns.elixir_editor, file, line |> String.to_integer())

    # Some editors may block iex, so we spawn a new process
    component_id = socket.assigns.id
    component_pid = self()

    spawn(fn ->
      case Editor.run_shell_cmd(cmd) do
        :ok ->
          :ok

        {:error, reason} ->
          send_update(component_pid, __MODULE__,
            id: component_id,
            editor_error: "Editor error: #{reason}"
          )
      end
    end)

    {:noreply, socket}
  end

  defp assign_node_type(socket) do
    node_type =
      socket.assigns.node_id
      |> TreeNode.type()
      |> case do
        :live_view -> "LiveView"
        :live_component -> "LiveComponent"
      end

    assign(socket, :node_type, node_type)
  end

  defp assign_async_node_module(socket) do
    node_id = socket.assigns.node_id
    pid = socket.assigns.lv_process.pid

    assign_async(socket, :node_module, fn ->
      case NodeQueries.get_module_from_id(node_id, pid) do
        {:ok, module} ->
          line = get_module_line(module)

          path = module.__info__(:compile) |> Keyword.get(:source) |> List.to_string()

          module_name = Parsers.module_to_string(module)

          {:ok,
           %{
             node_module: %{
               module_name: module_name,
               module_path: path,
               line: line
             }
           }}

        :error ->
          {:error, "Failed to get node module"}
      end
    end)
  end

  defp get_module_line(module) do
    case Code.fetch_docs(module) do
      {:docs_v1, _, _, _, _, %{source_annos: [{line, _column} | _]}, _} ->
        line

      _ ->
        1
    end
  end
end

# <.tooltip
#   :if={!@elixir_editor}
#   id={@id <> "-env-not-set"}
#   content="To open files, set the ELIXIR_EDITOR env or use an IDE terminal (e.g., VS Code)."
#   class="truncate"
# >
#   <.button
#     class="shrink-0 mr-2 mb-3"
#     variant="secondary"
#     id="open-in-editor"
#     size="sm"
#     disabled={!@elixir_editor}
#     phx-click="open-in-editor"
#     phx-target={@myself}
#     phx-value-file={node_module.module_path}
#     phx-value-line={node_module.line}
#   >
#     <.icon name="icon-external-link" class="w-4 h-4" /> Open in Editor
#   </.button>
# </.tooltip>
