defmodule LiveDebugger.App.Debugger.Web.LiveComponents.NodeBasicInfo do
  @moduledoc """
  Basic information about the node.
  """

  @elixir_editor System.get_env("ELIXIR_EDITOR") || nil

  use LiveDebugger.App.Web, :live_component

  import LiveDebugger.App.Web.Hooks.Flash, only: [push_flash: 3]
  require Logger
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.App.Debugger.Queries.Node, as: NodeQueries
  alias LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen
  alias LiveDebugger.App.Utils.Parsers

  alias LiveDebugger.App.Debugger.Web.Components.Pages

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign_node_type()
    |> assign_async_node_module()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:lv_process, :any, required: true)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :elixir_editor, @elixir_editor)

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
        <div class="flex flex-row gap-8 max-md_ct:flex-col max-md_ct:gap-2 md_ct:items-center p-3">
          <div class="min-w-0 flex flex-col gap-2 max-md_ct:border-b max-md_ct:border-default-border">
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
            <span class="font-medium">Path:</span>

            <div class="flex gap-2 min-w-0">
              <.tooltip
                id={@id <> "-current-node-module-path"}
                content={node_module.module_path <> ":" <> Integer.to_string(node_module.line)}
                class="truncate"
              >
                <%= node_module.module_path <> ":" <> Integer.to_string(node_module.line) %>
              </.tooltip>
              <.copy_button id="copy-button-module-path" value={node_module.module_path} />
            </div>

            <div class="flex flex-row items-center">
              <.button
                class="shrink-0 mr-2"
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
                :if={!@elixir_editor}
                id={@id <> "-current-node-module"}
                content="To ensure files open in the correct editor, please set the ELIXIR_EDITOR environment variable."
                class="truncate"
              >
                <.icon name="icon-info" class="text-error-text w-4 h-4" />
              </.tooltip>
            </div>

            <.button
              class="shrink-0 md_ct:ml-auto md_ct:hidden mb-3"
              variant="secondary"
              size="sm"
              id="show-components-tree-button"
              phx-click={Pages.get_open_sidebar_js(:node_inspector)}
            >
              <.icon name="icon-component" class="w-4 h-4" /> Show Components Tree
            </.button>
          </div>
          <div class="shrink-0 flex flex-col gap-2">
            <span class="font-medium">Type:</span>
            <span><%= @node_type %></span>
          </div>

          <.button
            class="shrink-0 md_ct:ml-auto"
            variant="secondary"
            size="sm"
            id="send-event-button"
            disabled={not @lv_process.alive?}
            phx-click="open-send-event"
            phx-target={@myself}
          >
            <.icon name="icon-send" class="w-4 h-4" /> Send Event
          </.button>
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
    socket
    |> open_editor(file, line |> String.to_integer())
    |> noreply()
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
          {_, _, _, _, _, %{source_annos: [{line, _column}]}, _} = Code.fetch_docs(module)

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

  defp open_editor(socket, file, line) when is_binary(file) and is_integer(line) do
    try do
      open_in_term_program_editor(file, line)
      socket
    rescue
      _ -> open_in_elixir_editor(socket, file, line)
    end
  end

  defp open_in_term_program_editor(file, line) do
    editor = System.get_env("TERM_PROGRAM")
    command = ["#{file}:#{line}"]
    System.cmd(editor, command, stderr_to_stdout: true)
  end

  defp open_in_elixir_editor(socket, file, line) do
    cond do
      editor = @elixir_editor || System.get_env("EDITOR") ->
        command =
          if editor =~ "__FILE__" or editor =~ "__LINE__" do
            editor
            |> String.replace("__FILE__", inspect(file))
            |> String.replace("__LINE__", Integer.to_string(line))
          else
            ["#{file}:#{line}"]
          end

        # Some editors may block iex, so we spawn a new process
        spawn(fn ->
          try do
            System.cmd(editor, command, stderr_to_stdout: true, into: IO.stream(:stdio, :line))
          rescue
            error -> Logger.error("Failed to open editor: " <> "#{editor} " <> inspect(error))
          end
        end)

        socket

      true ->
        push_flash(
          socket,
          :error,
          "Editor not detected. Run the server in your editor's terminal (e.g., VS Code) or set ELIXIR_EDITOR."
        )
    end
  end
end
