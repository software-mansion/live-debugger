defmodule LiveDebugger.App.Discovery.Web.LiveComponents.ActiveLiveViews do
  @moduledoc """
  Section component for displaying active LiveViews.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.Client
  alias LiveDebugger.App.Utils.Parsers
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

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
              target={@myself}
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

  def handle_event("highlight", params, socket) do
    socket
    |> highlight_element(params)
    |> noreply()
  end

  def handle_event("select-live-view", %{"id" => pid} = params, socket) do
    socket
    # Resets the highlight when the user selects LiveView
    |> highlight_element(params)
    |> push_navigate(to: RoutesHelper.debugger_node_inspector(pid))
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

  defp highlight_element(socket, params) do
    if SettingsStorage.get(:highlight_in_browser) do
      payload = %{
        attr: "id",
        val: params["search-value"],
        type: "LiveView",
        module: Parsers.module_to_string(params["module"]),
        id_value: params["id"],
        id_key: "PID"
      }

      Client.push_event!(params["root-socket-id"], "highlight", payload)
    end

    socket
  end
end
