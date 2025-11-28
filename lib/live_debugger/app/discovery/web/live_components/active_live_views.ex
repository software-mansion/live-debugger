defmodule LiveDebugger.App.Discovery.Web.LiveComponents.ActiveLiveViews do
  @moduledoc """
  Section component for displaying active LiveViews.
  """

  use LiveDebugger.App.Web, :live_component

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries

  def refresh(id) do
    send_update(__MODULE__, id: id, action: :refresh)
  end

  @impl true
  def update(%{action: :refresh}, socket) do
    socket
    |> start_async_grouped_lv_processes()
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(open?: true)
    |> assign(lv_processes_count: 0)
    |> assign(grouped_lv_processes: AsyncResult.loading())
    |> start_async_grouped_lv_processes()
    |> ok()
  end

  attr(:id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class={if(@open?, do: "flex-1")}>
      <.static_collapsible
        chevron_class="mr-2"
        class="h-full flex! flex-col max-lg:p-8 max-lg:pb-0 pt-8 lg:w-[60rem] lg:mx-auto"
        open={@open?}
        phx-click="toggle-open"
        phx-target={@myself}
      >
        <:label :let={open?}>
          <DiscoveryComponents.header
            title="Active LiveViews"
            lv_processes_count={@lv_processes_count}
            refresh_event="refresh-active"
            disabled?={!open?}
            target={@myself}
          />
        </:label>

        <div class="mt-6 flex-[1_0_0] overflow-y-scroll">
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
      </.static_collapsible>
    </div>
    """
  end

  @impl true
  def handle_event("refresh-active", _params, socket) do
    socket
    |> assign(grouped_lv_processes: AsyncResult.loading())
    |> start_async_grouped_lv_processes()
    |> noreply()
  end

  def handle_event("toggle-open", _params, socket) do
    socket
    |> assign(open?: !socket.assigns.open?)
    |> noreply()
  end

  @impl true
  def handle_async(
        :fetch_grouped_lv_processes,
        {:ok, {grouped_lv_processes, lv_processes_count}},
        socket
      ) do
    socket
    |> assign(lv_processes_count: lv_processes_count)
    |> assign(grouped_lv_processes: AsyncResult.ok(grouped_lv_processes))
    |> noreply()
  end

  defp start_async_grouped_lv_processes(socket) do
    start_async(
      socket,
      :fetch_grouped_lv_processes,
      &DiscoveryQueries.fetch_grouped_lv_processes/0
    )
  end
end
