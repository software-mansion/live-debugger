defmodule LiveDebuggerRefactor.App.Debugger.Web.DebuggerLive do
  @moduledoc false

  use LiveDebuggerRefactor.App.Web, :live_view

  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.Structs.LvProcess

  @impl true
  def mount(params, _session, socket) do
    with {:ok, pid} <- Parsers.string_to_pid(params["pid"]),
         %LvProcess{} = lv_process <- LiveDebuggerRefactor.Structs.LvProcess.new(pid) do
      {:ok, assign(socket, :lv_process, lv_process)}
    else
      _ ->
        {:ok, socket}
    end
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, assign(socket, :params, params)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col w-full h-full">
      <LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.NodeTracesLive.live_render
        :if={@lv_process}
        socket={@socket}
        id="node-traces"
        lv_process={@lv_process}
        params={%{}}
        class="flex-1"
      />

      <LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.GlobalTracesLive.live_render
        :if={@lv_process}
        socket={@socket}
        id="global-traces"
        lv_process={@lv_process}
        params={%{}}
        class="flex-1"
      />
      <button phx-click={Phoenix.LiveView.JS.push("open-sidebar", target: "#global-traces")}>
        Open global traces
      </button>
    </div>
    """
  end
end
