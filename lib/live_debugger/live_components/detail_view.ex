defmodule LiveDebugger.LiveComponents.DetailView do
  @moduledoc """
  This module is responsible for rendering the detail view of the TreeNode.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.ChannelService
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Components.Collapsible

  @impl true
  def mount(socket) do
    socket
    |> assign(:hide_assigns_section?, false)
    |> assign(:hide_info_section?, false)
    |> assign(:hide_events_section?, false)
    |> ok()
  end

  @impl true
  def update(%{new_trace: _new_trace}, socket) do
    socket
    |> assign_async_node_with_type()
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(%{
      node_id: assigns.node_id || assigns.pid,
      pid: assigns.pid,
      socket_id: assigns.socket_id
    })
    |> assign_async_node_with_type()
    |> ok()
  end

  attr(:node_id, :any, required: true)
  attr(:pid, :any, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-screen max-h-screen p-2 overflow-x-hidden overflow-y-auto lg:overflow-y-hidden">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed :let={reason}>
          <.alert variant="danger">
            Failed to fetch node details: <%= inspect(reason) %>
          </.alert>
        </:failed>
        <div class="grid grid-cols-1 lg:grid-cols-2 lg:h-full">
          <div class="flex flex-col max lg:border-r-2 border-primary lg:overflow-y-hidden">
            <.info_card
              node={node}
              node_type={@node_type.result}
              myself={@myself}
              hide?={@hide_info_section?}
            />
            <.assigns_card assigns={node.assigns} myself={@myself} hide?={@hide_assigns_section?} />
          </div>
          <.live_component
            id="event-list"
            module={LiveDebugger.LiveComponents.EventsList}
            debugged_node_id={@node_id}
            socket_id={@socket_id}
          />
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_event("toggle-visibility", %{"section" => section}, socket) do
    hide_section_key =
      case section do
        "info" -> :hide_info_section?
        "assigns" -> :hide_assigns_section?
        "events" -> :hide_events_section?
      end

    socket
    |> assign(hide_section_key, not socket.assigns[hide_section_key])
    |> noreply()
  end

  attr(:node, :any, required: true)
  attr(:node_type, :atom, required: true)
  attr(:myself, :any, required: true)
  attr(:hide?, :boolean, required: true)

  defp info_card(assigns) do
    ~H"""
    <Collapsible.section
      id="info"
      title={title(@node_type)}
      class="border-b-2 border-primary"
      hide?={@hide?}
      myself={@myself}
    >
      <div class=" flex flex-col gap-1">
        <.info_row name={id_type(@node_type)} value={TreeNode.display_id(@node)} />
        <.info_row name="Module" value={inspect(@node.module)} />
      </div>
    </Collapsible.section>
    """
  end

  attr(:name, :string, required: true)
  attr(:value, :any, required: true)

  defp info_row(assigns) do
    ~H"""
    <div class="flex gap-1 overflow-x-hidden">
      <div class="font-bold w-20 text-primary">
        <%= @name %>
      </div>
      <div class="font-semibold break-all">
        <%= @value %>
      </div>
    </div>
    """
  end

  defp title(:live_component), do: "LiveComponent"
  defp title(:live_view), do: "LiveView"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"

  attr(:assigns, :list, required: true)
  attr(:myself, :any, required: true)
  attr(:hide?, :boolean, required: true)

  defp assigns_card(assigns) do
    ~H"""
    <Collapsible.section
      id="assigns"
      class="border-b-2 lg:border-b-0 border-primary h-max overflow-y-hidden"
      hide?={@hide?}
      myself={@myself}
      title="Assigns"
    >
      <div class="relative w-full max-h-full border-2 border-gray-200 rounded-lg px-2 overflow-y-auto text-gray-600">
        <.modal_button id="assigns-display-fullscreen" class="absolute top-0 right-0">
          <.live_component
            id="assigns-display-fullscreen"
            module={LiveDebugger.LiveComponents.ElixirDisplay}
            node={TermParser.term_to_display_tree(@assigns)}
            level={1}
          />
        </.modal_button>
        <.live_component
          id="assigns-display"
          module={LiveDebugger.LiveComponents.ElixirDisplay}
          node={TermParser.term_to_display_tree(@assigns)}
          level={1}
        />
      </div>
    </Collapsible.section>
    """
  end

  defp assign_async_node_with_type(%{assigns: %{node_id: node_id, pid: pid}} = socket)
       when not is_nil(node_id) do
    assign_async(socket, [:node, :node_type], fn ->
      with {:ok, channel_state} <- ChannelService.state(pid),
           {:ok, node} <- ChannelService.get_node(channel_state, node_id),
           true <- not is_nil(node) do
        {:ok, %{node: node, node_type: TreeNode.type(node)}}
      else
        false -> {:error, :node_deleted}
        err -> err
      end
    end)
  end

  defp assign_async_node_with_type(socket) do
    socket
    |> assign(:node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    |> assign(:node_type, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
