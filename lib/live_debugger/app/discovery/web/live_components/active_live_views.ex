defmodule LiveDebugger.App.Discovery.Web.LiveComponents.ActiveLiveViews do
  @moduledoc """
  Section component for displaying active LiveViews.
  """

  use LiveDebugger.App.Web, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries

  def refresh(id) do
    send_update(__MODULE__, id: id)
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(:lv_processes_count, AsyncResult.loading())
    |> assign_async_grouped_lv_processes()
    |> ok()
  end

  attr(:id, :string, required: true)

  @impl true
  def render(assigns) do
    dbg({assigns.lv_processes_count, assigns.grouped_lv_processes})

    ~H"""
    <div id={@id} class="h-3/7 min-h-92 lg:min-h-120 max-lg:p-8 pt-8 lg:w-[60rem] lg:mx-auto">
      <DiscoveryComponents.header
        title="Active LiveViews"
        sessions_count={@lv_processes_count.result}
        refresh_event="refresh-active"
        target={@myself}
      />

      <div class="mt-6 max-h-72 lg:max-h-100 overflow-y-auto">
        <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
          <:loading><DiscoveryComponents.loading /></:loading>
          <:failed><DiscoveryComponents.failed /></:failed>
          <DiscoveryComponents.liveview_sessions
            id="live-sessions"
            grouped_lv_processes={grouped_lv_processes}
            empty_info="No active LiveViews"
          />
        </.async_result>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh-active", _params, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  defp assign_async_grouped_lv_processes(socket) do
    socket
    |> assign_async(
      [:grouped_lv_processes, :lv_processes_count],
      &DiscoveryQueries.fetch_grouped_lv_processes/0
    )
  end
end
