defmodule LiveDebugger.LiveViews.SidebarLive do
  @moduledoc """
  This live view is responsible for displaying the sidebar of the LiveDebugger.
  It receives events from the `ChannelDashboardLive` live to open the mobile sidebar.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Components.Links
  alias LiveDebugger.Services.ChannelService
  alias Phoenix.Socket.Message
  alias LiveDebugger.Utils.URL
  alias LiveDebugger.LiveComponents.NestedLiveViewsLinks
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:node_id, :string, required: true)
  attr(:url, :string, required: true)

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "url" => assigns.url,
      "parent_socket_id" => assigns.socket.id
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: "h-full"}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    parent_socket_id = session["parent_socket_id"]
    lv_process = session["lv_process"]

    if connected?(socket) do
      parent_socket_id
      |> PubSubUtils.node_changed_topic()
      |> PubSubUtils.subscribe!()

      lv_process.socket_id
      |> PubSubUtils.component_deleted_topic(lv_process.transport_pid)
      |> PubSubUtils.subscribe!()

      lv_process.socket_id
      |> PubSubUtils.ts_f_topic(lv_process.transport_pid, :render)
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, session["node_id"])
    |> assign(:url, session["url"])
    |> assign(:highlight?, false)
    |> assign(:hidden?, true)
    |> assign_async_tree()
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
    <div class="w-max flex bg-sidebar-bg shadow-custom border-x border-default-border h-full">
      <div class="hidden lg:flex max-h-full flex-col w-72 lg:w-80 gap-1 justify-between">
        <.sidebar_content
          id="sidebar-content"
          lv_process={@lv_process}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          highlight?={@highlight?}
          parent_lv_process={@parent_lv_process}
        />
        <.report_issue class="border-t border-default-border" />
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
        />
        <.report_issue class="border-t border-default-border" />
      </.sidebar_slide_over>
    </div>
    """
  end

  @impl true
  def handle_info({:new_trace, trace}, socket) do
    existing_node_ids = socket.assigns.existing_node_ids
    trace_node_id = Trace.node_id(trace)

    cond do
      existing_node_ids.ok? && !MapSet.member?(existing_node_ids.result, trace_node_id) ->
        updated_map_set = MapSet.put(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> update_nested_live_views_links()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      Trace.live_component_delete?(trace) ->
        updated_map_set = MapSet.delete(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
        |> update_nested_live_views_links()
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      true ->
        socket
    end
    |> noreply()
  end

  @impl true
  def handle_info({:node_changed, node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> noreply()
  end

  @impl true
  def handle_event("open-sidebar", _, socket) do
    socket
    |> assign(:hidden?, false)
    |> noreply()
  end

  @impl true
  def handle_event("select_node", params, socket) do
    %{"node_id" => node_id, "search-attribute" => attr, "search-value" => val} = params

    if Application.get_env(:live_debugger, :browser_features?) &&
         LiveDebugger.Feature.enabled?(:highlighting) do
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

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col max-h-full h-max">
      <.basic_info
        pid={@lv_process.pid}
        socket_id={@lv_process.socket_id}
        parent_lv_process={@parent_lv_process}
      />
      <.live_component
        id={@id <> "-nested-live-views"}
        module={NestedLiveViewsLinks}
        lv_process={@lv_process}
      />
      <.component_tree
        tree={@tree}
        selected_node_id={@node_id}
        max_opened_node_level={@max_opened_node_level}
        highlight?={@highlight?}
      />
    </div>
    """
  end

  slot(:inner_block)

  defp sidebar_slide_over(assigns) do
    ~H"""
    <div class="absolute z-20 top-0 left-0 bg-black/25 w-full h-full flex lg:hidden justify-end">
      <div
        class="w-80 h-full flex flex-col bg-sidebar-bg justify-between"
        phx-click-away="close_mobile_content"
      >
        <.icon_button
          icon="icon-cross-small"
          class="absolute top-4 right-4"
          variant="secondary"
          size="sm"
          phx-click="close_mobile_content"
        />
        <%= render_slot(@inner_block) %>
      </div>
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
          <Links.live_view lv_process={parent_lv_process} id="parent-live-view-link" />
        </div>
      </.async_result>
    </div>
    """
  end

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

  defp assign_async_tree(socket) do
    pid = socket.assigns.lv_process.pid

    assign_async(socket, [:tree, :max_opened_node_level], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
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
    {:ok, state} = ChannelService.state(pid)

    message = %Message{
      topic: state.topic,
      event: "diff",
      payload: %{e: [[event, payload]]},
      join_ref: state.join_ref
    }

    send(state.socket.transport_pid, state.serializer.encode!(message))
  end
end
