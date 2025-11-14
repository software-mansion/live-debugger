defmodule LiveDebugger.App.Debugger.AsyncJobs.Web.AsyncJobsLive do
  @moduledoc """
  This LiveView displays the async jobs of a particular node (`LiveView` or `LiveComponent`).
  """

  use LiveDebugger.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned

  alias LiveDebugger.App.Debugger.AsyncJobs.Queries, as: AsyncJobsQueries
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob

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
    |> start_async(:fetch_async_jobs, fn -> AsyncJobsQueries.fetch_async_jobs(lv_process.pid) end)
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full flex flex-1">
      <.section title="Async jobs" id="async-jobs" inner_class="mx-0 p-4" class="flex-1">
        <div class="w-full h-full flex flex-col gap-4">
          <.async_result :let={async_jobs} assign={@async_jobs}>
            <:failed>
              <div class="flex justify-center items-center h-full">
                <.alert class="w-full" with_icon heading="Error while fetching async jobs">
                  Check logs for more
                </.alert>
              </div>
            </:failed>
            <%= if Enum.empty?(async_jobs) do %>
              <div class="w-full flex items-center justify-center">
                <span class=" text-secondary-text">No async jobs found</span>
              </div>
            <% end %>

            <%= for async_job <- async_jobs do %>
              <div class="flex gap-2">
                <span class="text-sm">
                  <%= inspect(AsyncJob.identifier(async_job)) %>
                </span>
                <span class="text-sm"><%= inspect(async_job.pid) %></span>
              </div>
            <% end %>
          </.async_result>
        </div>
      </.section>
    </div>
    """
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> noreply()
  end

  def handle_info(%TraceReturned{function: :render}, socket) do
    pid = socket.assigns.lv_process.pid

    socket
    |> start_async(:fetch_async_jobs, fn -> AsyncJobsQueries.fetch_async_jobs(pid) end)
    |> noreply()
  end

  def handle_info(%TraceReturned{ets_ref: ets_ref, trace_id: trace_id}, socket) do
    trace_tuple = {ets_ref, trace_id}

    socket
    |> start_async(:fetch_async_jobs, fn -> AsyncJobsQueries.fetch_async_jobs(trace_tuple) end)
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_async(:fetch_async_jobs, {:ok, {:ok, async_jobs}}, socket)
      when is_list(async_jobs) do
    socket
    |> assign(:async_jobs, AsyncResult.ok(async_jobs))
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
end
