defmodule LiveDebugger.App.Debugger.Streams.Web.StreamsLive do
  @moduledoc """
  This LiveView displays streams of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.Streams.Web.Hooks
  alias LiveDebugger.App.Debugger.Streams.Web.Components, as: StreamsComponents

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.StreamUpdated

  @doc """
  Renders the `StreamsLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `params` - query parameters of the page.
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:node_id, :any, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    parent_pid = session["parent_pid"]
    node_id = session["node_id"]

    if connected?(socket) do
      Bus.receive_events!(parent_pid)
      Bus.receive_states!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> Hooks.Streams.init()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={stream_names} assign={@stream_names}>
        <:loading>
          <StreamsComponents.loading />
        </:loading>
        <:failed>
          <StreamsComponents.failed />
        </:failed>

        <StreamsComponents.stream_section
          :if={Map.has_key?(assigns, :streams) and stream_names != []}
          stream_names={stream_names}
          existing_streams={@streams}
        />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_info(
        %StreamUpdated{stream: stream, dom_id_fun: dom_id_fun},
        socket
      ) do
    socket
    |> Hooks.Streams.assign_async_streams(stream, dom_id_fun)
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
