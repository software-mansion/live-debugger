defmodule LiveDebugger.App.Debugger.AsyncJobs.Web.AsyncJobsLive do
  @moduledoc """
  This LiveView displays the async jobs of a particular node (`LiveView` or `LiveComponent`).
  """

  use LiveDebugger.App.Web, :live_view

  import LiveDebugger.App.Debugger.AsyncJobs.Components

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned

  alias LiveDebugger.App.Debugger.AsyncJobs.Queries, as: AsyncJobsQueries

  @async_jobs_sectinon_id "async-jobs"

  @doc """
  Renders the `AsyncJobsLive` as a nested LiveView component.

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
      Bus.receive_traces!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> assign(:assigns_search_phrase, "")
    |> assign(:async_jobs, AsyncResult.ok([]))
    |> start_async(:fetch_async_jobs, fn ->
      AsyncJobsQueries.fetch_async_jobs(lv_process.pid, node_id)
    end)
    |> ok()
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, id: @async_jobs_sectinon_id)

    ~H"""
    <div class="max-w-full flex flex-1">
      <.collapsible_section
        title="Async jobs"
        id={@id}
        inner_class="mx-0 p-4"
        class="flex-1"
        save_state_in_browser={true}
      >
        <div class="w-full h-full flex flex-col gap-2">
          <.async_result :let={async_jobs} assign={@async_jobs}>
            <:failed>
              <%= async_jobs_failed(@async_jobs) %>
            </:failed>
            <div :if={Enum.empty?(async_jobs)} class="w-full flex items-center justify-center">
              <span class=" text-secondary-text">No active async jobs found</span>
            </div>
            <.async_job
              :for={async_job <- async_jobs}
              id={"async-job-#{inspect(async_job.pid)}"}
              async_job={async_job}
            />
          </.async_result>
        </div>
      </.collapsible_section>
    </div>
    """
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    pid = socket.assigns.lv_process.pid

    socket
    |> assign(:node_id, node_id)
    |> start_async(:fetch_async_jobs, fn ->
      AsyncJobsQueries.fetch_async_jobs(pid, node_id)
    end)
    |> noreply()
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, socket) do
    async_jobs = socket.assigns.async_jobs.result || []
    updated_async_jobs = Enum.filter(async_jobs, fn async_job -> async_job.pid != pid end)

    socket
    |> assign(:async_jobs, AsyncResult.ok(updated_async_jobs))
    |> push_event("#{@async_jobs_sectinon_id}-summary-pulse", %{})
    |> noreply()
  end

  def handle_info(%TraceReturned{function: :render}, socket), do: {:noreply, socket}

  def handle_info(
        %TraceReturned{ets_ref: ets_ref, trace_id: trace_id, cid: cid, pid: pid},
        socket
      ) do
    trace_tuple = {ets_ref, trace_id}
    node_id = socket.assigns.node_id

    if node_id == cid or (node_id == pid and cid == nil) do
      socket
      |> start_async(:fetch_async_jobs, fn -> AsyncJobsQueries.fetch_async_jobs(trace_tuple) end)
      |> noreply()
    else
      {:noreply, socket}
    end
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:fetch_async_jobs, {:ok, {:ok, []}}, socket) do
    socket
    |> assign(:async_jobs, AsyncResult.ok([]))
    |> noreply()
  end

  def handle_async(:fetch_async_jobs, {:ok, {:ok, async_jobs}}, socket)
      when is_list(async_jobs) do
    Enum.each(async_jobs, fn async_job ->
      Process.monitor(async_job.pid)
    end)

    socket
    |> assign(:async_jobs, AsyncResult.ok(async_jobs))
    |> push_event("#{@async_jobs_sectinon_id}-summary-pulse", %{})
    |> noreply()
  end

  def handle_async(:fetch_async_jobs, {:ok, {:error, :not_alive_or_not_a_liveview}}, socket) do
    socket
    |> assign(:async_jobs, AsyncResult.ok([]))
    |> noreply()
  end

  def handle_async(:fetch_async_jobs, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:async_jobs, AsyncResult.failed(AsyncResult.loading(), reason))
    |> noreply()
  end

  def handle_async(:fetch_async_jobs, {:exit, reason}, socket) do
    socket
    |> assign(:async_jobs, AsyncResult.failed(AsyncResult.loading(), reason))
    |> noreply()
  end

  defp async_jobs_failed(assigns) do
    ~H"""
    <div class="flex justify-center items-center h-full">
      <.alert class="w-full" with_icon heading="Error while fetching async jobs">
        Check logs for more
      </.alert>
    </div>
    """
  end
end
