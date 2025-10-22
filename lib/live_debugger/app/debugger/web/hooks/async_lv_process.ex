defmodule LiveDebugger.App.Debugger.Web.Hooks.AsyncLvProcess do
  @moduledoc """
  Hooks for asynchronous LVProcess assignment.
  """

  require Logger

  use LiveDebugger.App.Web, :hook

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.API.LiveViewDiscovery

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.DebuggerMounted

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn -> get_lv_process_with_root_socket_id(pid) end)
  end

  defp handle_async(:lv_process, {:ok, {%LvProcess{} = lv_process, root_socket_id}}, socket) do
    if Process.alive?(lv_process.pid) do
      Bus.broadcast_event!(%DebuggerMounted{
        debugger_pid: self(),
        debugged_pid: lv_process.pid
      })

      socket
      |> assign(:lv_process, AsyncResult.ok(lv_process))
      |> assign(:root_socket_id, root_socket_id)
    else
      socket
      |> put_flash(:error, "LiveView process died")
      |> push_navigate(to: RoutesHelper.discovery())
    end
    |> halt()
  end

  defp handle_async(:lv_process, {:ok, nil}, socket) do
    socket
    |> put_flash(:error, "LiveView process not found")
    |> push_navigate(to: RoutesHelper.discovery())
    |> halt()
  end

  defp handle_async(:lv_process, {:ok, :root_socket_id_not_found}, socket) do
    socket
    |> push_navigate(to: RoutesHelper.error("root_socket_id_not_found"))
    |> halt()
  end

  defp handle_async(:lv_process, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching information for process: #{inspect(reason)}"
    )

    socket
    |> push_navigate(to: RoutesHelper.error("unexpected_error"))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp get_lv_process_with_root_socket_id(pid) do
    with %LvProcess{} = lv_process <- LvProcessQueries.get_lv_process_with_retries(pid),
         {:ok, root_socket_id} <- get_root_socket_id(lv_process) do
      {lv_process, root_socket_id}
    else
      {:error, :root_socket_id_not_found} -> :root_socket_id_not_found
      nil -> nil
    end
  end

  defp get_root_socket_id(%LvProcess{embedded?: false, nested?: false} = lv_process) do
    {:ok, lv_process.socket_id}
  end

  defp get_root_socket_id(%LvProcess{embedded?: true, nested?: false} = lv_process) do
    case find_root_lv_process_over_transport_pid(lv_process.transport_pid) do
      %LvProcess{socket_id: socket_id} -> {:ok, socket_id}
      _ -> {:ok, lv_process.socket_id}
    end
  end

  defp get_root_socket_id(lv_process) do
    lv_process.root_pid
    |> LvProcessQueries.get_lv_process()
    |> case do
      %LvProcess{embedded?: false} = lv_process -> {:ok, lv_process.socket_id}
      %LvProcess{embedded?: true, nested?: false} = lv_process -> get_root_socket_id(lv_process)
      _ -> {:error, :root_socket_id_not_found}
    end
  end

  defp find_root_lv_process_over_transport_pid(transport_pid) do
    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.find(fn
      %LvProcess{transport_pid: ^transport_pid, embedded?: false, nested?: false} -> true
      _ -> false
    end)
  end
end
