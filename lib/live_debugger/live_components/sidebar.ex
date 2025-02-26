defmodule LiveDebugger.LiveComponents.Sidebar do
  @moduledoc """
  Sidebar component which displays tree of live view and it's live components.
  It changes path to `<base_url>/<node_id>` when a node is selected.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Components.Tree
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.Logger

  @report_issue_url "https://github.com/software-mansion-labs/live-debugger/issues/new/choose"

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

  def update(%{show_sidebar?: true}, socket) do
    socket
    |> assign(:hidden?, false)
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
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class="w-max flex bg-white shadow-custom border border-secondary-200">
      <div class="hidden sm:flex max-h-full flex-col w-64 gap-1">
        <.report_issue />
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
        />
      </div>
      <.sidebar_slide_over :if={not @hidden?} myself={@myself}>
        <.sidebar_content
          pid={@pid}
          socket_id={@socket_id}
          tree={@tree}
          max_opened_node_level={@max_opened_node_level}
          node_id={@node_id}
          myself={@myself}
        />
      </.sidebar_slide_over>
    </div>
    """
  end

  @impl true
  def handle_event("select_node", %{"node_id" => node_id}, socket) do
    socket
    |> push_patch(to: "#{socket.assigns.base_url}/#{node_id}")
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

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex flex-col max-h-full h-max">
      <.basic_info pid={@pid} socket_id={@socket_id} />
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
        class="w-64 h-full flex flex-col bg-white/100"
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

  defp report_issue(assigns) do
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class="px-2 flex items-center gap-1 text-xs">
      <.icon name="icon-bug-ant" />
      <div>
        See any issue?
        <span>
          Report it <.link href={@report_issue_url} target="_blank" class="underline hover:text-white">here</.link>.
        </span>
      </div>
    </div>
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
end
