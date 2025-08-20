defmodule LiveDebugger.App.Discovery.Web.WindowDiscoveryLive do
  @moduledoc """
  This view is a variant of the LiveViews dashboard, but it is used to display LiveViews in the given window.
  It cannot be accessed from the browser directly, but:
  - it is used when there are many LiveViews in the same window, and we cannot find a single successor.
  - in case of extension this replaces the LiveViews dashboard, since extension works in a single window.
  """

  use LiveDebugger.App.Web, :live_view

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.App.Discovery.Web.Components, as: DiscoveryComponents
  alias LiveDebugger.App.Web.Components.Navbar, as: NavbarComponents
  alias LiveDebugger.App.Discovery.Queries, as: DiscoveryQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewDied
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  @impl true
  def mount(%{"transport_pid" => string_transport_pid}, _session, socket) do
    string_transport_pid
    |> Parsers.string_to_pid()
    |> case do
      {:ok, transport_pid} ->
        if connected?(socket) do
          Bus.receive_events!()
        end

        socket
        |> assign(transport_pid: transport_pid)
        |> assign_async_grouped_lv_processes()

      :error ->
        push_navigate(socket, to: RoutesHelper.error("invalid_pid"))
    end
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="window-dashboard" class="flex-1 min-w-[25rem] grid grid-rows-[auto_1fr]">
      <NavbarComponents.navbar class={"grid  #{if @in_iframe?, do: "grid-cols-[auto_1fr_auto] ", else: "grid-cols-[auto_auto_1fr_auto] pl-2"} "}>
        <NavbarComponents.return_link
          class={if @in_iframe?, do: "hidden", else: ""}
          return_link={RoutesHelper.discovery()}
        />
        <NavbarComponents.live_debugger_logo />
        <NavbarComponents.fill />
        <NavbarComponents.settings_button return_to={@url} />
      </NavbarComponents.navbar>
      <div class="flex-1 max-lg:p-8 pt-8 lg:w-[60rem] lg:m-auto">
        <DiscoveryComponents.header title="Active LiveViews in a single window" />

        <div class="mt-6">
          <.async_result :let={grouped_lv_processes} assign={@grouped_lv_processes}>
            <:loading><DiscoveryComponents.loading /></:loading>
            <:failed><DiscoveryComponents.failed /></:failed>
            <DiscoveryComponents.live_sessions grouped_lv_processes={grouped_lv_processes} />
          </.async_result>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  @impl true
  def handle_info(%LiveViewBorn{transport_pid: transport_pid}, socket)
      when transport_pid == socket.assigns.transport_pid do
    socket
    |> assign_async_grouped_lv_processes()
    |> noreply()
  end

  def handle_info(%LiveViewDied{pid: pid}, socket) do
    with {:ok, group} <- get_lv_processes_group(socket),
         true <- in_group?(group, pid) do
      assign_async_grouped_lv_processes(socket)
    else
      _ -> socket
    end
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_grouped_lv_processes(%{assigns: %{transport_pid: transport_pid}} = socket) do
    assign_async(
      socket,
      :grouped_lv_processes,
      fn -> DiscoveryQueries.fetch_grouped_lv_processes(transport_pid) end,
      reset: true
    )
  end

  defp get_lv_processes_group(socket) do
    transport_pid = socket.assigns.transport_pid

    case socket.assigns.grouped_lv_processes.result do
      nil -> {:error, :empty_result}
      %{^transport_pid => group} -> {:ok, group}
    end
  end

  defp in_group?(group, dead_pid) do
    lv_processes = Map.keys(group)
    nested_lv_processes = group |> Map.values() |> Enum.concat()

    (lv_processes ++ nested_lv_processes)
    |> Enum.any?(fn %LvProcess{pid: pid} -> pid == dead_pid end)
  end
end
