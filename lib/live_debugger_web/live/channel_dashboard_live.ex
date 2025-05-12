defmodule LiveDebuggerWeb.ChannelDashboardLive do
  @moduledoc false

  use LiveDebuggerWeb, :live_view
  use LiveDebuggerWeb.Hooks.LinkedView

  require Logger

  alias Phoenix.LiveView.JS
  alias LiveDebugger.Utils.URL

  alias LiveDebugger.Structs.TreeNode

  alias LiveDebuggerWeb.StateLive
  alias LiveDebuggerWeb.TracesLive
  alias LiveDebuggerWeb.SidebarLive
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @impl true
  def handle_params(params, url, socket) do
    socket
    |> assign_node_id(params)
    |> assign(:url, URL.to_relative(url))
    |> noreply()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-screen h-screen grid grid-rows-[auto_1fr]">
      <.navbar return_link?={true}>
        <div class="grow flex items-center justify-end">
          <.nav_icon
            :if={@lv_process.ok?}
            phx-click={JS.push("open-sidebar", target: "#sidebar")}
            class="flex lg:hidden"
            icon="icon-menu-hamburger"
          />
        </div>
      </.navbar>
      <.async_result :let={lv_process} assign={@lv_process}>
        <:loading>
          <div class="m-auto flex items-center justify-center">
            <.spinner size="xl" />
          </div>
        </:loading>
        <div class="flex overflow-hidden">
          <SidebarLive.live_render
            id="sidebar"
            class="h-full"
            socket={@socket}
            lv_process={lv_process}
            url={@url}
            node_id={@node_id || lv_process.pid}
          />

          <div class="flex grow flex-col xl:flex-row gap-4 xl:gap-8 p-8 overflow-y-auto xl:overflow-y-hidden max-w-screen-2xl mx-auto scrollbar-main">
            <StateLive.live_render
              id="node-state-lv"
              class="flex xl:w-1/2"
              socket={@socket}
              lv_process={lv_process}
              node_id={@node_id || lv_process.pid}
            />
            <TracesLive.live_render
              id="traces-list"
              class="flex max-xl:grow xl:w-1/2"
              socket={@socket}
              lv_process={lv_process}
              node_id={@node_id || lv_process.pid}
              root_pid={self()}
            />
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  defp assign_node_id(socket, %{"node_id" => node_id}) do
    case TreeNode.id_from_string(node_id) do
      {:ok, id} ->
        socket.id
        |> PubSubUtils.node_changed_topic()
        |> PubSubUtils.broadcast({:node_changed, id})

        assign(socket, :node_id, id)

      :error ->
        Logger.error("Invalid node_id: #{inspect(node_id)}")

        socket
        |> push_flash("Invalid `node_id` param")
        |> assign(:node_id, nil)
    end
  end

  defp assign_node_id(socket, _params) do
    assign(socket, :node_id, nil)
  end
end
