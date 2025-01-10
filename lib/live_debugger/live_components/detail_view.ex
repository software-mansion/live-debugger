defmodule LiveDebugger.LiveComponents.DetailView do
  @moduledoc """
  This module is responsible for rendering the detail view of the TreeNode.
  """

  alias LiveDebugger.Services.TreeNode
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Services.ChannelStateScraper

  use LiveDebuggerWeb, :live_component

  @impl true
  def mount(socket) do
    socket
    |> assign(:hide_assigns_section?, false)
    |> assign(:hide_info_section?, false)
    |> assign(:hide_events_section?, false)
    |> ok()
  end

  @impl true
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
    <div class="flex flex-col w-full h-screen max-h-screen p-2 overflow-x-hidden overflow-y-auto md:overflow-y-hidden">
      <.async_result :let={node} assign={@node}>
        <:loading>
          <div class="w-full flex items-center justify-center">
            <.spinner size="md" />
          </div>
        </:loading>
        <:failed :let={reason}>
          <.alert color="danger">
            Failed to fetch node details: {inspect(reason)}
          </.alert>
        </:failed>
        <div class="grid grid-cols-1 md:grid-cols-2 md:h-full">
          <div class="flex flex-col max md:border-r-2 border-swm-blue md:overflow-y-hidden">
            <.info_card
              node={node}
              node_type={@node_type.result}
              myself={@myself}
              hide?={@hide_info_section?}
            />
            <.assigns_card assigns={node.assigns} myself={@myself} hide?={@hide_assigns_section?} />
          </div>
          <.events_card
            node_id={@node_id}
            socket_id={@socket_id}
            myself={@myself}
            hide?={@hide_events_section?}
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
    <.section
      id="info"
      title={title(@node_type)}
      class="border-b-2 border-swm-blue"
      hide?={@hide?}
      myself={@myself}
    >
      <div class=" flex flex-col gap-1">
        <.info_row name={id_type(@node_type)} value={TreeNode.parsed_id(@node)} />
        <.info_row name="Module" value={inspect(@node.module)} />
        <.info_row name="HTML ID" value={@node.id} />
      </div>
    </.section>
    """
  end

  attr(:name, :string, required: true)
  attr(:value, :any, required: true)

  defp info_row(assigns) do
    ~H"""
    <div class="flex gap-1 overflow-x-hidden">
      <div class="font-bold w-20 text-swm-blue">
        {@name}
      </div>
      <div class="font-semibold break-all">
        {@value}
      </div>
    </div>
    """
  end

  defp title(:live_component), do: "Live Component"
  defp title(:live_view), do: "Live View"

  defp id_type(:live_component), do: "CID"
  defp id_type(:live_view), do: "PID"

  attr(:assigns, :list, required: true)
  attr(:myself, :any, required: true)
  attr(:hide?, :boolean, required: true)

  defp assigns_card(assigns) do
    ~H"""
    <.section
      id="assigns"
      class="border-b-2 md:border-b-0 border-swm-blue h-max overflow-y-hidden"
      hide?={@hide?}
      myself={@myself}
      title="Assigns"
    >
      <pre class="w-full max-h-full border-2 border-gray-200 rounded-lg px-2 overflow-y-auto text-gray-600">
        <div class="whitespace-pre">{inspect(@assigns, pretty: true, structs: false)}</div>
      </pre>
    </.section>
    """
  end

  attr(:node_id, :string, required: true)
  attr(:socket_id, :string, required: true)
  attr(:myself, :any, required: true)
  attr(:hide?, :boolean, required: true)

  defp events_card(assigns) do
    ~H"""
    <.section
      title="Events"
      id="events"
      class="h-full md:overflow-y-auto"
      myself={@myself}
      hide?={@hide?}
    >
      <.live_component
        id="event-list"
        module={LiveDebugger.LiveComponents.EventsList}
        debugged_node_id={@node_id}
        socket_id={@socket_id}
      />
    </.section>
    """
  end

  attr(:id, :string, required: true)
  attr(:myself, :any, required: true)
  attr(:title, :string, default: nil)
  attr(:class, :string, default: "")
  attr(:hide?, :boolean, default: false)

  slot(:inner_block)

  defp section(assigns) do
    ~H"""
    <div class={[
      "flex flex-col p-4",
      @class
    ]}>
      <div
        phx-click="toggle-visibility"
        phx-value-section={@id}
        phx-target={@myself}
        class="flex gap-2 items-center md:pointer-events-none md:cursor-default cursor-pointer"
      >
        <.h3 class="text-swm-blue" no_margin={true}>{@title}</.h3>
        <.icon
          name="hero-chevron-down-solid"
          class={[
            "text-swm-blue md:hidden",
            if(@hide?, do: "transform rotate-180")
          ]}
        />
      </div>
      <div class={[
        "flex h-full overflow-y-auto overflow-x-hidden rounded-md bg-white opacity-90 text-black p-2",
        if(@hide?, do: "hidden md:flex")
      ]}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  defp assign_async_node_with_type(%{assigns: %{node_id: node_id, pid: pid}} = socket)
       when not is_nil(node_id) do
    assign_async(socket, [:node, :node_type], fn ->
      with {:ok, node} <- ChannelStateScraper.get_node_from_pid(pid, node_id) do
        {:ok, %{node: node, node_type: TreeNode.type(node)}}
      end
    end)
  end

  defp assign_async_node_with_type(socket) do
    socket
    |> assign(:node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
    |> assign(:node_type, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end
