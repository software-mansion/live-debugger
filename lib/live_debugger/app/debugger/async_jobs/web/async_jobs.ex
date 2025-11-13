defmodule LiveDebugger.App.Debugger.AsyncJobs.Web.AsyncJobsLive do
  @moduledoc """
  This LiveView displays the async jobs of a particular node (`LiveView` or `LiveComponent`).
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

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
      Bus.receive_states!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> assign(:assigns_search_phrase, "")
    |> assign(:async_jobs, [])
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-full flex flex-1">
      <.section title="Async jobs" id="async-jobs" inner_class="mx-0 my-4 px-4" class="flex-1">
        <div class="w-full h-full flex flex-col gap-4">
          <%= for async_job <- @async_jobs do %>
            <div class="flex gap-2">
              <span class="text-sm">
                <%= inspect(AsyncJob.identifier(async_job)) %>
              </span>
              <span class="text-sm"><%= inspect(async_job.pid) %></span>
            </div>
          <% end %>
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

  def handle_info(%StateChanged{}, socket) do
    dbg("State changed")

    {:ok, async_jobs} = AsyncJobsQueries.fetch_async_jobs(socket.assigns.lv_process.pid)

    socket
    |> assign(:async_jobs, async_jobs)
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}
end
