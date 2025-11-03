defmodule LiveDebugger.App.Debugger.Resources.Web.ResourcesLive do
  @moduledoc """
  Nested LiveView for displaying resources information for the LiveView process.
  """

  use LiveDebugger.App.Web, :live_view

  require Logger

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.DeadViewModeEntered
  alias LiveDebugger.App.Debugger.Resources.Queries.ProcessInfo, as: ProcessInfoQueries
  alias LiveDebugger.App.Debugger.Resources.Components.Chart
  alias LiveDebugger.App.Debugger.Resources.Components
  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown

  @default_refresh_interval 5000

  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "id" => assigns.id,
      "lv_process" => assigns.lv_process,
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
  def mount(
        _params,
        %{"parent_pid" => parent_pid, "lv_process" => lv_process, "id" => id},
        socket
      ) do
    if connected?(socket) do
      Bus.receive_events!(parent_pid)
    end

    socket
    |> assign(id: id)
    |> assign(parent_pid: parent_pid)
    |> assign(lv_process: lv_process)
    |> assign(refresh_interval: @default_refresh_interval)
    |> assign(process_info: AsyncResult.loading())
    |> assign_async_process_info()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="grow p-8 overflow-y-auto scrollbar-main">
      <div class="w-full min-w-[25rem] max-w-screen-2xl mx-auto">
        <.section
          title="Process Information"
          id="process-info"
          inner_class="mx-0 my-4 px-4"
          class="flex-1"
        >
          <:right_panel>
            <Components.refresh_select
              id="refresh-select"
              name="refresh-select"
              selected_interval={@refresh_interval}
            />
          </:right_panel>
          <.async_result :let={process_info} assign={@process_info}>
            <:loading>
              <div class="flex h-[36vh] w-full items-center justify-center">
                <.spinner size="xl" />
              </div>
            </:loading>
            <:failed :let={error_type}>
              <.alert
                with_icon={true}
                heading="Debugged LiveView process is not alive"
                class="w-full"
                :if={error_type == :error}
              >
              You can use continue button to find its successor.
              </.alert>
              <.alert
                with_icon={true}
                heading="Error while loading process information"
                class="w-full"
                :if={error_type == :exit}
              >
              Check logs for more details.
              </.alert>
            </:failed>
            <div class="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-2 w-full">
              <Components.process_info process_info={process_info} />
              <Chart.render id="process-info-chart" class="min-h-[44vh] lg:min-h-[36h]" />
            </div>
          </.async_result>
        </.section>
      </div>
    </div>
    """
  end

  @impl true
  def handle_async(:process_info, {:ok, {:ok, process_info}}, socket) do
    Process.send_after(self(), :refresh_process_info, socket.assigns.refresh_interval)

    socket
    |> assign(process_info: AsyncResult.ok(socket.assigns.process_info, process_info))
    |> Chart.append_new_data(process_info)
    |> noreply()
  end

  def handle_async(:process_info, {:ok, {:error, _reason}}, socket) do
    socket
    |> assign(process_info: AsyncResult.failed(socket.assigns.process_info, :error))
    |> noreply()
  end

  def handle_async(:process_info, {:exit, reason}, socket) do
    Logger.error("Failed to fetch process information: #{inspect(reason)}")

    socket
    |> assign(process_info: AsyncResult.failed(socket.assigns.process_info, :exit))
    |> noreply()
  end

  @impl true
  def handle_info(
        %DeadViewModeEntered{debugger_pid: pid},
        %{assigns: %{parent_pid: pid}} = socket
      ) do
    socket
    |> assign(:lv_process, socket.assigns.lv_process |> LvProcess.set_alive(false))
    |> noreply()
  end

  def handle_info(:refresh_process_info, socket) do
    socket
    |> assign_async_process_info()
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("change-refresh-interval", %{"refresh-select" => value}, socket) do
    refresh_interval = String.to_integer(value)

    LiveDropdown.close("refresh-select")

    socket
    |> assign(refresh_interval: refresh_interval)
    |> noreply()
  end

  defp assign_async_process_info(socket) do
    pid = socket.assigns.lv_process.pid

    socket
    |> start_async(:process_info, fn ->
      ProcessInfoQueries.get_info(pid)
    end)
  end
end
