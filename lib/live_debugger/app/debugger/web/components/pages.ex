defmodule LiveDebugger.App.Debugger.Web.Components.Pages do
  @moduledoc """
  Set of components that are used to layout the pages of the debugger.
  """

  use LiveDebugger.App.Web, :component

  alias Phoenix.LiveView.Socket, as: LiveViewSocket
  alias Phoenix.LiveView.JS
  alias LiveDebugger.App.Debugger.CallbackTracing.Web, as: CallbackTracingWeb
  alias LiveDebugger.App.Debugger.Web.LiveComponents.NodeInspectorSidebar
  alias LiveDebugger.App.Debugger.Web.LiveComponents.NodeBasicInfo
  alias LiveDebugger.App.Debugger.ComponentsTree.Web.ComponentsTreeLive
  alias LiveDebugger.App.Debugger.NodeState.Web.NodeStateLive
  alias LiveDebugger.App.Debugger.NestedLiveViewLinks.Web.NestedLiveViewLinksLive
  alias LiveDebugger.Structs.LvProcess

  @node_inspector_sidebar_id "node-inspector-sidebar"
  @global_traces_id "global-traces"

  attr(:socket, LiveViewSocket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:url, :string, required: true)
  attr(:node_id, :any, required: true)
  attr(:root_socket_id, :string, required: true)

  def node_inspector(assigns) do
    assigns = assign(assigns, :sidebar_id, @node_inspector_sidebar_id)

    ~H"""
    <div class="flex grow flex-col gap-4 p-8 overflow-y-auto max-w-screen-2xl mx-auto scrollbar-main">
      <NodeStateLive.live_render
        id="node-state-lv"
        class="flex"
        socket={@socket}
        lv_process={@lv_process}
        node_id={@node_id}
      />
      <CallbackTracingWeb.NodeTracesLive.live_render
        id="traces-list"
        class="flex"
        socket={@socket}
        lv_process={@lv_process}
        node_id={@node_id}
      />
    </div>
    <.live_component module={NodeInspectorSidebar} id={@sidebar_id}>
      <.live_component
        module={NodeBasicInfo}
        id="node-inspector-basic-info"
        lv_process={@lv_process}
        node_id={@node_id}
      />
      <NestedLiveViewLinksLive.live_render
        id="nested-live-view-links"
        lv_process={@lv_process}
        socket={@socket}
      />
      <ComponentsTreeLive.live_render
        id="components-tree"
        lv_process={@lv_process}
        socket={@socket}
        root_socket_id={@root_socket_id}
        node_id={@node_id}
        url={@url}
        class="overflow-x-hidden"
      />
      <.report_issue class="border-t border-default-border" />
    </.live_component>
    """
  end

  attr(:socket, LiveViewSocket, required: true)
  attr(:lv_process, LvProcess, required: true)

  def global_traces(assigns) do
    assigns = assign(assigns, :id, @global_traces_id)

    ~H"""
    <CallbackTracingWeb.GlobalTracesLive.live_render
      id={@id}
      class="flex overflow-hidden w-full"
      socket={@socket}
      lv_process={@lv_process}
    />
    """
  end

  @spec get_open_sidebar_js(live_action :: atom()) :: JS.t()
  def get_open_sidebar_js(live_action) when is_atom(live_action) do
    case live_action do
      :node_inspector -> JS.push("open-sidebar", target: "##{@node_inspector_sidebar_id}")
      :global_traces -> JS.push("open-sidebar", target: "##{@global_traces_id}")
    end
  end

  def close_node_inspector_sidebar() do
    Phoenix.LiveView.send_update(NodeInspectorSidebar,
      id: @node_inspector_sidebar_id,
      hidden?: true
    )
  end
end
