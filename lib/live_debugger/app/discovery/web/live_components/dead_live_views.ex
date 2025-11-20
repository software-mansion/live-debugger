defmodule LiveDebugger.App.Discovery.Web.LiveComponents.DeadLiveViews do
  @moduledoc """
  Section component for displaying dead LiveViews.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries
  alias LiveDebugger.App.Discovery.Actions, as: DiscoveryActions

  def refresh(id) do
    send_update(__MODULE__, id: id, action: :refresh)
  end

  @impl true
  def update(%{action: :refresh}, socket) do
    socket
    |> assign_async_dead_grouped_lv_processes()
    |> ok()
  end

  def update(%{dead_liveviews?: value}, socket) do
    socket
    |> assign(dead_liveviews?: value)
    |> assign_async_dead_grouped_lv_processes()
    |> ok()
  end

  def update(assigns, socket) do
    socket
    |> assign(assigns)
    |> assign(dead_liveviews?: SettingsStorage.get(:dead_liveviews))
    |> assign_async_dead_grouped_lv_processes()
    |> ok()
  end

  attr(:id, :string, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id} class="h-3/7 max-lg:p-8 py-8 lg:w-[60rem] lg:mx-auto">
      <.collapsible
        id="dead-liveviews-collapsible"
        chevron_class="mr-2"
        label_class={if(!@dead_liveviews?, do: "w-max")}
        open={@dead_liveviews?}
        phx-click="toggle-dead-liveviews"
        phx-target={@myself}
      >
        <:label>
          <DiscoveryComponents.header
            title="Dead LiveViews"
            refresh_event="refresh-dead"
            disabled?={!@dead_liveviews?}
            target={@myself}
          />
        </:label>

        <div :if={@dead_liveviews?}>
          <DiscoveryComponents.garbage_collection_info />

          <div class="mt-6 max-h-72 lg:max-h-100 overflow-y-auto">
            <.async_result :let={dead_grouped_lv_processes} assign={@dead_grouped_lv_processes}>
              <:loading><DiscoveryComponents.loading /></:loading>
              <:failed><DiscoveryComponents.failed /></:failed>
              <DiscoveryComponents.liveview_sessions
                id="dead-sessions"
                grouped_lv_processes={dead_grouped_lv_processes}
                empty_info="No dead LiveViews"
                remove_event="remove-lv-state"
                target={@myself}
              />
            </.async_result>
          </div>
        </div>
      </.collapsible>
    </div>
    """
  end

  @impl true
  def handle_event("refresh-dead", _params, socket) do
    socket
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  def handle_event("toggle-dead-liveviews", _params, socket) do
    new_value = !socket.assigns.dead_liveviews?

    DiscoveryActions.update_dead_liveviews_setting(new_value)
    |> case do
      {:ok, true} ->
        socket
        |> assign(dead_liveviews?: true)
        |> assign_async_dead_grouped_lv_processes()

      {:ok, false} ->
        assign(socket, dead_liveviews?: false)

      {:error, _reason} ->
        push_flash(socket, :error, "Failed to update setting")
    end
    |> noreply()
  end

  def handle_event("remove-lv-state", %{"pid" => string_pid}, socket) do
    {:ok, pid} = Parsers.string_to_pid(string_pid)
    DiscoveryActions.remove_lv_process_state!(pid)

    socket
    |> assign_async_dead_grouped_lv_processes()
    |> noreply()
  end

  defp assign_async_dead_grouped_lv_processes(socket) do
    if socket.assigns.dead_liveviews? do
      assign_async(
        socket,
        :dead_grouped_lv_processes,
        &DiscoveryQueries.fetch_dead_grouped_lv_processes/0,
        reset: true
      )
    else
      socket
    end
  end
end
