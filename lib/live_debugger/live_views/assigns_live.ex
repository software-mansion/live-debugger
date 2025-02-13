defmodule LiveDebugger.LiveViews.AssignsLive do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Components.ElixirDisplay

  alias Phoenix.LiveView.AsyncResult
  alias Phoenix.PubSub

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)
  attr(:node_id, :any, required: true)

  def live_render(assigns) do
    session = %{
      "socket_id" => assigns.socket_id,
      "node_id" => assigns.node_id,
      "pid" => assigns.pid
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__, id: @id, session: @session) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket_id = session["socket_id"]
    node_id = session["node_id"]

    if connected?(socket) do
      PubSub.subscribe(LiveDebugger.PubSub, "lvdbg/#{socket_id}/node_changed")
      PubSub.subscribe(LiveDebugger.PubSub, "#{socket_id}/#{inspect(node_id)}/:render")
    end

    socket
    |> assign(socket_id: socket_id)
    |> assign(node_id: node_id)
    |> assign(pid: session["pid"])
    |> assign_async_node()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.collapsible_section
      id="node-assigns"
      class="border-b-2 lg:border-b-0 border-primary h-max overflow-y-hidden"
      title="Assigns"
    >
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="sm" />
          </div>
        </:loading>
        <:failed>
          <.alert class="w-full" variant="danger" with_icon heading="Error fetching node assigns">
            Check logs for more
          </.alert>
        </:failed>
        <div class="relative w-full max-h-full border-2 border-gray-200 rounded-lg p-4 overflow-y-auto text-gray-600">
          <.fullscreen_wrapper id="node-assigns-display-fullscreen" class="absolute top-0 right-0">
            <ElixirDisplay.term
              id="node-assigns-display-fullscreen"
              node={TermParser.term_to_display_tree(node.assigns)}
              level={1}
            />
          </.fullscreen_wrapper>
          <ElixirDisplay.term
            id="node-assigns-display"
            node={TermParser.term_to_display_tree(node.assigns)}
            level={1}
          />
        </div>
      </.async_result>
    </.collapsible_section>
    """
  end

  @impl true
  def handle_info({:node_changed, node_id}, socket) do
    socket
    |> assign(node_id: node_id)
    |> assign_async_node()
    |> noreply()
  end

  @impl true
  def handle_info({:new_trace, _trace}, socket) do
    socket
    |> assign_async_node()
    |> noreply()
  end

  defp assign_async_node(%{assigns: %{node_id: nil}} = socket) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp assign_async_node(%{assigns: %{node_id: node_id, pid: pid}} = socket) do
    assign_async(socket, [:node], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node: node}}
      else
        false -> {:error, :node_deleted}
        err -> err
      end
    end)
  end
end
