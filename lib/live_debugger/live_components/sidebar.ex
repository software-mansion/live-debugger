defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  It changes path to `<base_url>/<node_id>` when a node is selected.
  """
  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelService
  alias Phoenix.Socket.Message

  @impl true
  def mount(socket) do
    socket
    |> hide_sidebar_side_over()
    |> assign(:highlight?, false)
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
        |> assign(:existing_node_ids, Map.put(existing_node_ids, :result, updated_map_set))

      Trace.live_component_delete?(trace) ->
        updated_map_set = MapSet.delete(existing_node_ids.result, trace_node_id)

        socket
        |> assign_async_tree()
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
      base_url: assigns.base_url
    })
    |> assign_async_tree()
    |> assign_async_existing_node_ids()
    |> ok()
  end

  attr(:lv_process, :any, required: true)
  attr(:node_id, :any, required: true)
  attr(:base_url, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id="sidebar" class="w-max flex bg-white shadow-custom border border-secondary-200">
      <div class="hidden sm:flex max-h-full flex-col w-64 gap-1 justify-between">
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
          highlight?={@highlight?}
        />
        <.report_issue class="border-t border-secondary-200" />
      </div>
      <.sidebar_slide_over :if={not @hidden?} myself={@myself}>
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
          highlight?={@highlight?}
        />
        <.report_issue class="border-t border-secondary-200" />
      </.sidebar_slide_over>
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket =
      if socket.assigns.highlight? do
        send_event(socket.assigns.pid, "pulse")
        assign(socket, :highlight?, false)
      else
        socket
      end

    socket
    |> push_patch(to: "#{socket.assigns.base_url}/#{node_id}")
    |> hide_sidebar_side_over()
    |> noreply()
  end

  @impl true
  def handle_event("highlight", params, socket) do
    if socket.assigns.highlight? do
      %{"search_attribute" => attr, "search_value" => val} = params

      send_event(socket.assigns.pid, "highlight", %{attr: attr, val: val})
    end

    noreply(socket)
  end

  @impl true
  def handle_event("toggle-highlight", _, socket) do
    socket
    |> update(:highlight?, &(not &1))
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
  attr(:highlight?, :boolean, required: true)

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col max-h-full h-max">
      <.basic_info pid={@pid} socket_id={@socket_id} />
      <.component_tree
        tree={@tree}
        selected_node_id={@node_id}
        target={@myself}
        max_opened_node_level={@max_opened_node_level}
        highlight?={@highlight?}
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
        class="w-64 h-full flex flex-col bg-white/100 justify-between"
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

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  defp basic_info(assigns) do
    ~H"""
    <div class="w-full p-6 shrink-0 flex flex-col gap-2 border-b border-secondary-200">
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
    </div>
    """
  end

  attr(:tree, :any, required: true)
  attr(:target, :any, required: true)
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

      <%= if Application.get_env(:live_debugger, :browser_features?) do %>
        <div class="flex justify-center mt-3">
          <.button
            phx-target={@target}
            phx-click="toggle-highlight"
            data-highlight={if @highlight?, do: "on", else: "off"}
          >
            <%= if @highlight?, do: "Highlight On", else: "Highlight Off" %>
          </.button>
        </div>
      <% end %>

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

  defp handle_error({:error, :not_alive} = error, pid, _) do
    Logger.info("Process #{inspect(pid)} is not alive")
    error
  end

  defp handle_error(error, _, error_message) do
    Logger.error(error_message <> inspect(error))
    error
  end

  defp send_event(pid, event, payload \\ nil) do
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
