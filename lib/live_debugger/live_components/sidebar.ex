defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  It adds `node_id` to QueryParams when a node is selected.
  """
  use LiveDebuggerWeb, :live_component

  require Logger

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelService

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

  def update(assigns, socket) do
    socket
    |> assign(%{
      pid: assigns.pid,
      socket_id: assigns.socket_id,
      node_id: assigns.node_id,
      base_url: assigns.base_url
    })
    |> assign_async_tree()
    |> assign_async_existing_node_ids()
    |> ok()
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:base_url, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-max h-max flex">
      <div class="hidden sm:flex flex-col w-60 min-h-max h-screen bg-primary gap-1 pt-4 p-2 pr-3">
        <.sidebar_label socket={@socket} />
        <.separate_bar />
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          node_id={@node_id}
          myself={@myself}
        />
      </div>
      <div class="flex sm:hidden flex-col gap-2 w-14 pt-4 p-1 h-screen bg-primary items-center justify-start">
        <.link patch="/">
          <.sidebar_icon_button icon="hero-home-solid" />
        </.link>
        <.sidebar_icon_button icon="hero-bars-3" phx-click="show_mobile_content" phx-target={@myself} />
        <.sidebar_slide_over :if={not @hidden?} myself={@myself}>
          <:header>
            <.sidebar_label socket={@socket} />
          </:header>
          <.sidebar_content
            pid={@pid}
            socket_id={@socket_id}
            tree={@tree}
            node_id={@node_id}
            myself={@myself}
          />
        </.sidebar_slide_over>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket
    |> push_patch(to: "#{socket.assigns.base_url}?node_id=#{node_id}")
    |> hide_sidebar_side_over()
    |> noreply()
  end

  def handle_event("show_mobile_content", _params, socket) do
    socket
    |> show_sidebar_slide_over()
    |> noreply()
  end

  @impl true
  def handle_event("close_mobile_content", _params, socket) do
    socket
    |> hide_sidebar_side_over()
    |> noreply()
  end

  attr(:socket, :map, required: true)

  defp sidebar_label(assigns) do
    ~H"""
    <.link patch="/" class="flex items-center gap-2">
      <.icon class="text-white" name="hero-chevron-left-solid" />
      <.h3 class="text-white">LiveDebugger</.h3>
    </.link>
    """
  end

  attr(:socket_id, :string, required: true)
  attr(:pid, :any, required: true)
  attr(:tree, :any, required: true)
  attr(:node_id, :any, required: true)
  attr(:myself, :any, required: true)

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 p-2">
      <.basic_info pid={@pid} socket_id={@socket_id} />
      <.separate_bar />
      <.component_tree tree={@tree} selected_node_id={@node_id} target={@myself} />
    </div>
    """
  end

  attr(:myself, :any, required: true)
  slot(:header)
  slot(:inner_block)

  defp sidebar_slide_over(assigns) do
    ~H"""
    <div class="absolute z-20 top-0 left-0 w-full h-screen bg-primary text-white p-2">
      <div class="w-full flex justify-between p-2">
        <%= render_slot(@header) %>
        <.sidebar_icon_button
          icon="hero-x-mark"
          phx-click="close_mobile_content"
          phx-target={@myself}
        />
      </div>
      <.separate_bar />
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  defp show_sidebar_slide_over(socket) do
    assign(socket, :hidden?, false)
  end

  defp hide_sidebar_side_over(socket) do
    assign(socket, :hidden?, true)
  end

  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  defp basic_info(assigns) do
    ~H"""
    <.card class="p-4 flex flex-col gap-1 bg-gray-200 text-black">
      <%= for {text, value} <- [
        {"Monitored socket:", @socket_id},
        {"Debugged PID:", Parsers.pid_to_string(@pid)}
      ] do %>
        <div class="font-semibold text-primary"><%= text %></div>
        <div><%= value %></div>
      <% end %>
    </.card>
    """
  end

  attr(:tree, :any, required: true)
  attr(:target, :any, required: true)
  attr(:selected_node_id, :string, default: nil)

  defp component_tree(assigns) do
    ~H"""
    <.async_result :let={tree} assign={@tree}>
      <:loading>
        <div class="w-full flex justify-center mt-5"><.spinner class="text-white" /></div>
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
        class="bg-gray-200"
      />
    </.async_result>
    """
  end

  attr(:icon, :string, required: true)
  attr(:link, :string, default: nil)
  attr(:rest, :global)

  defp sidebar_icon_button(assigns) do
    ~H"""
    <.button color="white" {@rest}>
      <.icon class="text-primary" name={@icon} />
    </.button>
    """
  end

  defp separate_bar(assigns) do
    ~H"""
    <div class="border-b h-0 border-white my-4"></div>
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

    assign_async(socket, :tree, fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, tree} <- ChannelService.build_tree(channel_state) do
        {:ok, %{tree: tree}}
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
end
