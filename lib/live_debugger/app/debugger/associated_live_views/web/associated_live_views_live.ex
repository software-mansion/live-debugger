defmodule LiveDebugger.App.Debugger.AssociatedLiveViews.Web.AssociatedLiveViewsLive do
  @moduledoc """
  This LiveView displays a tree of associated LiveViews of provided LiveView process
  with buttons redirecting to each of them.
  """

  use LiveDebugger.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Client
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Debugger.Web.Components, as: DebuggerComponents
  alias LiveDebugger.App.Debugger.Queries.LvProcess, as: LvProcessQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  @doc """
  Renders the `AssociatedLiveViewsLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  """
  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
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
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]

    if connected?(socket) do
      Bus.receive_events!()
    end

    socket
    |> assign(lv_process: lv_process)
    |> assign_async_associated_lv_processes()
    |> assign_async_parent_lv_process()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full px-4 pt-4 pb-5 gap-3 flex flex-col border-b border-default-border mt-1 z">
      <.async_result :let={associated_lv_processes} assign={@associated_lv_processes}>
        <:loading>
          <.spinner size="sm" class="m-auto" />
        </:loading>
        <p class="pl-2 shrink-0 font-medium text-secondary-text pb-1 pt-1">
          <%= if Enum.empty?(associated_lv_processes),
            do: "No associated LiveViews",
            else: "Associated LiveViews" %>
        </p>
        <%= if not Enum.empty?(associated_lv_processes) do %>
          <DebuggerComponents.associated_lv_processes_tree
            lv_processes={associated_lv_processes}
            current_lv_process_pid={@lv_process.pid}
          />
        <% end %>
      </.async_result>
    </div>
    """
  end

  @impl true
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

  def handle_event(_, _, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_info(%LiveViewBorn{transport_pid: tpid}, socket) do
    if socket.assigns.lv_process.transport_pid == tpid do
      assign_async_associated_lv_processes(socket)
    else
      socket
    end
    |> noreply()
  end

  def handle_info(%LiveViewDied{transport_pid: tpid}, socket) do
    if Process.alive?(socket.assigns.lv_process.pid) and
         socket.assigns.lv_process.transport_pid == tpid do
      assign_async_associated_lv_processes(socket)
    else
      socket
    end
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_associated_lv_processes(
         %{assigns: %{lv_process: %{transport_pid: tpid}}} = socket
       ) do
    assign_async(
      socket,
      :associated_lv_processes,
      fn ->
        lv_processes =
          tpid
          |> LiveViewDiscovery.debugged_lv_processes()
          |> Enum.map(fn lv_process ->
            LvProcess.set_root_socket_id(
              lv_process,
              LiveViewDiscovery.get_root_socket_id(lv_process)
            )
          end)
          |> LiveViewDiscovery.group_lv_processes()
          |> Map.get(tpid, %{})

        {:ok, %{associated_lv_processes: lv_processes}}
      end
    )
  end

  defp assign_async_parent_lv_process(socket) do
    parent_pid = socket.assigns.lv_process.parent_pid

    case parent_pid do
      nil ->
        assign(socket, :parent_lv_process, AsyncResult.ok(nil))

      pid ->
        assign_async(socket, :parent_lv_process, fn ->
          {:ok, %{parent_lv_process: LvProcessQueries.get_lv_process_with_retries(pid)}}
        end)
    end
  end

  # defp known_child_lv_process?(socket, pid) do
  #   case socket.assigns.associated_lv_processes.result do
  #     nil -> false
  #     # result -> Enum.any?(result, fn %LvProcess{pid: associated_pid} -> associated_pid == pid end)
  #     result -> dfs(result, pid)
  #   end
  # end

  # defp dfs(nil, _pid) do
  #   false
  # end

  # defp dfs(tree, pid) do
  #   tree
  #   |> Enum.any?(fn
  #     {%LvProcess{pid: ^pid}, _} -> true
  #     {_, children} -> Enum.any?(children, &dfs(&1, pid))
  #   end)
  # end

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
