defmodule LiveDebuggerWeb.Live.Nested.NodeInspectorSidebarLive do
  @moduledoc """
  This live view is responsible for displaying the sidebar of the LiveDebugger.
  It receives events from the `LvProcessLive` live to open the mobile sidebar.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  import LiveDebuggerWeb.Helpers.NestedLiveViewHelper

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Components.Tree
  alias LiveDebuggerWeb.Components.Links
  alias LiveDebugger.Services.ChannelService
  alias Phoenix.Socket.Message
  alias LiveDebugger.Utils.URL
  alias LiveDebuggerWeb.LiveComponents.NestedLiveViewsLinks
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Helpers.StateHelper

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:url, :string, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
      "url" => assigns.url,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:aside, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    parent_pid = session["parent_pid"]
    lv_process = session["lv_process"]

    if connected?(socket) do
      parent_pid
      |> PubSubUtils.params_changed_topic()
      |> PubSubUtils.subscribe!()

      lv_process.pid
      |> PubSubUtils.state_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign_node_id(session)
    |> assign(:url, session["url"])
    |> assign(:highlight?, false)
    |> assign(:hidden?, true)
    |> assign_async_tree()
    |> assign_async_node_module()
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
    <div class="w-max flex bg-sidebar-bg shadow-custom h-full">
      <div class="hidden lg:flex max-h-full flex-col w-72 border-x border-default-border lg:w-80 gap-1 justify-between">
        <.sidebar_content
          id="sidebar-content"
          lv_process={@lv_process}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          highlight?={@highlight?}
          parent_lv_process={@parent_lv_process}
          node_module={@node_module}
        />
      </div>
      <.sidebar_slide_over :if={not @hidden?}>
        <.sidebar_content
          id="sidebar-content-slide-over"
          lv_process={@lv_process}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          highlight?={@highlight?}
          parent_lv_process={@parent_lv_process}
          node_module={@node_module}
        />
      </.sidebar_slide_over>
    </div>
    """
  end

  @impl true
  def handle_info({:state_changed, new_state, trace}, socket) do
    existing_node_ids = socket.assigns.existing_node_ids
    trace_node_id = Trace.node_id(trace)

    cond do
      existing_node_ids.ok? && !MapSet.member?(existing_node_ids.result, trace_node_id) ->
        updated_map_set = MapSet.put(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree(new_state)
        |> update_nested_live_views_links()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      Trace.live_component_delete?(trace) ->
        updated_map_set = MapSet.delete(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree(new_state)
        |> update_nested_live_views_links()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      true ->
        socket
    end
    |> noreply()
  end

  @impl true
  def handle_info({:params_changed, new_params}, socket) do
    socket
    |> assign_node_id(new_params)
    |> assign_async_node_module()
    |> noreply()
  end

  @impl true
  def handle_event("open-sidebar", _, socket) do
    socket
    |> assign(:hidden?, false)
    |> noreply()
  end

  @impl true
  def handle_event(
        "select_node",
        %{"node-id" => node_id, "search-attribute" => attr, "search-value" => val},
        socket
      ) do
    if LiveDebugger.Feature.enabled?(:highlighting) do
      if !socket.assigns.hidden? && socket.assigns.highlight? do
        send_event(socket.assigns.lv_process.pid, "highlight", %{attr: attr, val: val})
      end

      send_event(socket.assigns.lv_process.pid, "pulse", %{attr: attr, val: val})
    end

    socket
    |> push_patch(to: URL.upsert_query_param(socket.assigns.url, "node_id", node_id))
    |> assign(:hidden?, true)
    |> noreply()
  end

  @impl true
  def handle_event("highlight", params, socket) do
    if socket.assigns.highlight? do
      %{"search-attribute" => attr, "search-value" => val} = params

      send_event(socket.assigns.lv_process.pid, "highlight", %{attr: attr, val: val})
    end

    noreply(socket)
  end

  @impl true
  def handle_event("toggle-highlight", _, socket) do
    if socket.assigns.highlight? do
      send_event(socket.assigns.lv_process.pid, "highlight")
    end

    socket
    |> update(:highlight?, &(not &1))
    |> noreply()
  end

  @impl true
  def handle_event("close_mobile_content", _params, socket) do
    socket
    |> assign(:hidden?, true)
    |> noreply()
  end

  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:tree, :any, required: true)
  attr(:node_id, :any, required: true)
  attr(:max_opened_node_level, :any, required: true)
  attr(:highlight?, :boolean, required: true)
  attr(:parent_lv_process, :any, required: true)
  attr(:node_module, :any, required: true)

  defp sidebar_content(assigns) do
    ~H"""
    <div class="grid grid-rows-[auto_auto_1fr_auto] h-full">
      <.basic_info
        id={@id <> "-basic-info"}
        module={@node_module}
        parent_lv_process={@parent_lv_process}
        node_type={TreeNode.type(@node_id)}
      />
      <.live_component
        id={@id <> "-nested-live-views"}
        module={NestedLiveViewsLinks}
        lv_process={@lv_process}
      />
      <.component_tree
        id={@id}
        tree={@tree}
        selected_node_id={@node_id}
        max_opened_node_level={@max_opened_node_level}
        highlight?={@highlight?}
      />
      <.report_issue class="border-t border-default-border" />
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:module, :atom, required: true)
  attr(:node_type, :atom, required: true)
  attr(:parent_lv_process, :map, required: true)

  defp basic_info(assigns) do
    ~H"""
    <div id={@id} class="w-full p-6 shrink-0 flex flex-col gap-2 border-b border-default-border">
      <.async_result :let={parent_lv_process} assign={@parent_lv_process}>
        <:loading>
          <div class="w-full h-30 flex justify-center items-center"><.spinner size="sm" /></div>
        </:loading>
        <div class="w-full flex flex-col">
          <span class="font-medium">Type:</span>
          <span><%= node_type(@node_type) %></span>
        </div>
        <div class="w-full flex flex-col">
          <span class="font-medium">Module:</span>

          <div :if={@module.ok?} class="flex gap-2">
            <.tooltip
              id={@id <> "-current-node-module"}
              content={Parsers.module_to_string(@module.result)}
              class="truncate max-w-[232px]"
            >
              <%= Parsers.module_to_string(@module.result) %>
            </.tooltip>
            <.copy_button id="module-name" value={Parsers.module_to_string(@module.result)} />
          </div>
        </div>
        <div :if={parent_lv_process} class="w-full flex flex-col">
          <span class="font-medium">Parent LiveView Process</span>
          <Links.live_view lv_process={parent_lv_process} id="parent-live-view-link" />
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:tree, :any, required: true)
  attr(:max_opened_node_level, :any, required: true)
  attr(:selected_node_id, :string, default: nil)
  attr(:highlight?, :boolean, required: true)

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
        id={"component-tree-" <> @id}
        title="Components Tree"
        selected_node_id={@selected_node_id}
        tree_node={tree}
        max_opened_node_level={@max_opened_node_level.result}
        highlight?={@highlight?}
      />
    </.async_result>
    """
  end

  defp update_nested_live_views_links(socket) do
    base_id = "sidebar-content-nested-live-views"
    mobile_id = "sidebar-content-slide-over-nested-live-views"

    ids =
      if socket.assigns.hidden? do
        [base_id]
      else
        [base_id, mobile_id]
      end

    for id <- ids do
      send_update(NestedLiveViewsLinks, id: id, refresh: true)
    end

    socket
  end

  defp assign_async_node_module(%{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket) do
    assign_async(socket, :node_module, fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node_module: node.module}}
      else
        err -> err
      end
    end)
  end

  defp assign_async_existing_node_ids(socket) do
    pid = socket.assigns.lv_process.pid

    assign_async(socket, :existing_node_ids, fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node_ids} <- ChannelService.node_ids(channel_state) do
        {:ok, %{existing_node_ids: MapSet.new(node_ids)}}
      else
        error -> handle_error(error, pid, "Failed to get existing node ids: ")
      end
    end)
  end

  defp assign_async_tree(socket, state \\ nil) do
    pid = socket.assigns.lv_process.pid

    assign_async(socket, [:tree, :max_opened_node_level], fn ->
      with {:ok, channel_state} <- StateHelper.maybe_get_state(pid, state),
           {:ok, tree} <- ChannelService.build_tree(channel_state) do
        {:ok, %{tree: tree, max_opened_node_level: Tree.max_opened_node_level(tree)}}
      else
        error -> handle_error(error, pid, "Failed to build tree: ")
      end
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

  defp send_event(pid, event, payload \\ %{}) do
    {:ok, state} = ProcessService.state(pid)

    message = %Message{
      topic: state.topic,
      event: "diff",
      payload: %{e: [[event, payload]]},
      join_ref: state.join_ref
    }

    send(state.socket.transport_pid, state.serializer.encode!(message))
  end

  defp node_type(:live_component), do: "LiveComponent"
  defp node_type(:live_view), do: "LiveView"
end
