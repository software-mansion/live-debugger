defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  It adds `node_id` query param to the URL when a node is clicked.
  """
  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.URL
  alias LiveDebugger.LiveHelpers.Routes

  @impl true
  def mount(socket) do
    socket
    |> hide_sidebar_side_over()
    |> ok()
  end

  @impl true
  def update(%{new_trace: trace}, socket) do
    existing_node_ids = socket.assigns.existing_node_ids
    trace_node_id = Trace.node_id(trace)

    cond do
      existing_node_ids.ok? and not MapSet.member?(existing_node_ids.result, trace_node_id) ->
        updated_map_set = MapSet.put(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> assign_async_nested_lv_processes()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      Trace.live_component_delete?(trace) ->
        updated_map_set = MapSet.delete(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> assign_async_nested_lv_processes()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      true ->
        socket
    end
    |> ok()
  end

  def update(%{show_sidebar?: true}, socket) do
    socket
    |> assign(:hidden?, false)
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(%{
      pid: assigns.lv_process.pid,
      socket_id: assigns.lv_process.socket_id,
      node_id: assigns.node_id,
      url: assigns.url,
      lv_process: assigns.lv_process
    })
    |> assign_async_tree()
    |> assign_async_nested_lv_processes()
    |> assign_async_parent_lv_process()
    |> assign_async_existing_node_ids()
    |> ok()
  end

  attr(:lv_process, :any, required: true)
  attr(:node_id, :any, required: true)
  attr(:url, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-max flex bg-sidebar-bg shadow-custom border-x border-default-border">
      <div class="hidden sm:flex max-h-full flex-col w-72 md:w-80 gap-1 justify-between">
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
          parent_lv_process={@parent_lv_process}
          nested_lv_processes={@nested_lv_processes}
        />
        <.report_issue class="border-t border-default-border" />
      </div>
      <.sidebar_slide_over :if={not @hidden?} myself={@myself}>
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
          parent_lv_process={@parent_lv_process}
          nested_lv_processes={@nested_lv_processes}
        />
        <.report_issue class="border-t border-default-border" />
      </.sidebar_slide_over>
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket
    |> push_patch(to: URL.upsert_query_param(socket.assigns.url, "node_id", node_id))
    |> hide_sidebar_side_over()
    |> noreply()
  end

  @impl true
  def handle_event("close_mobile_content", _params, socket) do
    socket
    |> hide_sidebar_side_over()
    |> noreply()
  end

  attr(:socket_id, :string, required: true)
  attr(:pid, :any, required: true)
  attr(:tree, :any, required: true)
  attr(:node_id, :any, required: true)
  attr(:myself, :any, required: true)
  attr(:max_opened_node_level, :any, required: true)
  attr(:parent_lv_process, :any, required: true)
  attr(:nested_lv_processes, :any, required: true)

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col max-h-full h-max">
      <.basic_info pid={@pid} socket_id={@socket_id} parent_lv_process={@parent_lv_process} />
      <.nested_liveviews_links nested_lv_processes={@nested_lv_processes} />
      <.component_tree
        tree={@tree}
        selected_node_id={@node_id}
        target={@myself}
        max_opened_node_level={@max_opened_node_level}
      />
    </div>
    """
  end

  attr(:myself, :any, required: true)
  slot(:inner_block)

  defp sidebar_slide_over(assigns) do
    ~H"""
    <div class="absolute z-20 top-0 left-0 bg-black/25 w-full h-full flex sm:hidden justify-end">
      <div
        class="w-80 h-full flex flex-col bg-sidebar-bg justify-between"
        phx-click-away="close_mobile_content"
        phx-target={@myself}
      >
        <.icon_button
          icon="icon-cross-small"
          class="absolute top-4 right-4"
          variant="secondary"
          size="sm"
          phx-click="close_mobile_content"
          phx-target={@myself}
        />
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp hide_sidebar_side_over(socket) do
    assign(socket, :hidden?, true)
  end

  attr(:nested_lv_processes, :any, required: true)

  defp nested_liveviews_links(assigns) do
    ~H"""
    <div class="w-full px-4 py-3 gap-3 flex flex-col border-b border-default-border">
      <.async_result :let={nested_lv_processes} assign={@nested_lv_processes}>
        <:loading>
          <.spinner size="sm" class="m-auto" />
        </:loading>
        <p class="pl-2 shrink-0 font-medium text-secondary-text">Nested LiveViews</p>
        <%= if Enum.empty?(nested_lv_processes) do %>
          <p class="pl-7">No nested LiveViews</p>
        <% else %>
          <div class="pl-2 flex flex-col gap-1">
            <.link
              :for={process <- nested_lv_processes}
              href={Routes.channel_dashboard(process.socket_id, process.transport_pid)}
              class="w-full flex gap-1 text-primary-text"
            >
              <.icon name="icon-nested" class="w-4 h-4 shrink-0 text-link-primary" />
              <p class="text-link-primary truncate">
                <%= Parsers.module_to_string(process.module) %>
              </p>
            </.link>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:parent_lv_process, :any, required: true)

  defp basic_info(assigns) do
    ~H"""
    <div class="w-full p-6 shrink-0 flex flex-col gap-2 border-b border-default-border">
      <.async_result :let={parent_lv_process} assign={@parent_lv_process}>
        <:loading>
          <div class="w-full h-30 flex justify-center items-center"><.spinner size="sm" /></div>
        </:loading>
        <div
          :for={
            {text, value} <- [
              {"Monitored socket:", @socket_id},
              {"Debugged PID:", Parsers.pid_to_string(@pid)}
            ]
          }
          class="w-full flex flex-col"
        >
          <span class="font-medium"><%= text %></span>
          <span><%= value %></span>
        </div>
        <div :if={parent_lv_process} class="w-full flex flex-col">
          <span class="font-medium">Parent LiveView Process</span>
          <.link
            href={
              Routes.channel_dashboard(parent_lv_process.socket_id, parent_lv_process.transport_pid)
            }
            class="text-link-primary hover:text-link-primary-hover truncate"
          >
            <%= Parsers.module_to_string(parent_lv_process.module) %>
          </.link>
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:tree, :any, required: true)
  attr(:target, :any, required: true)
  attr(:max_opened_node_level, :any, required: true)
  attr(:selected_node_id, :string, default: nil)

  defp component_tree(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner size="sm" /></div>
      </:loading>
      <:failed :let={_error}>
        <.alert variant="danger">Couldn't load a tree</.alert>
      </:failed>
      <Tree.tree
        :if={tree}
        title="Components Tree"
        selected_node_id={@selected_node_id}
        tree_node={tree}
        event_target={@target}
        max_opened_node_level={@max_opened_node_level.result}
      />
    </.async_result>
    """
  end

  defp assign_async_existing_node_ids(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :existing_node_ids, fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node_ids} <- ChannelService.node_ids(channel_state) do
        {:ok, %{existing_node_ids: MapSet.new(node_ids)}}
      else
        error -> handle_error(error, pid, "Failed to get existing node ids: ")
      end
    end)
  end

  defp assign_async_tree(socket) do
    pid = socket.assigns.pid

    assign_async(socket, [:tree, :max_opened_node_level], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, tree} <- ChannelService.build_tree(channel_state) do
        {:ok, %{tree: tree, max_opened_node_level: Tree.max_opened_node_level(tree)}}
      else
        error -> handle_error(error, pid, "Failed to build tree: ")
      end
    end)
  end

  defp assign_async_nested_lv_processes(socket) do
    pid = socket.assigns.pid

    assign_async(socket, :nested_lv_processes, fn ->
      {:ok, %{nested_lv_processes: LiveViewDiscoveryService.children_lv_processes(pid)}}
    end)
  end

  defp assign_async_parent_lv_process(socket) do
    lv_process = socket.assigns.lv_process

    assign_async(socket, :parent_lv_process, fn ->
      {:ok, %{parent_lv_process: LvProcess.parent(lv_process)}}
    end)
  end

  defp handle_error({:error, :not_alive} = error, pid, _) do
    Logger.info("Process #{inspect(pid)} is not alive")
    error
  end

  defp handle_error(error, _, error_message) do
    Logger.error(error_message <> inspect(error))
    error
  end
end
