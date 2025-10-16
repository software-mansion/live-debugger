defmodule LiveDebugger.App.Debugger.Web.Hooks.AsyncLvProcess do
  @moduledoc """
  Hooks for asynchronous LVProcess assignment.
  """

  use LiveDebugger.App.Web, :hook

  alias LiveDebugger.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebugger.App.Debugger.Queries.State, as: StateQueries
  alias LiveDebugger.App.Events.DebuggerMounted
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper
  alias LiveDebugger.Bus
  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveView.AsyncResult

  require Logger

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn -> get_lv_process_with_root_socket_id(pid) end)
  end

  defp handle_async(:lv_process, {:ok, {%LvProcess{} = lv_process, root_socket_id}}, socket) do
    if_result =
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

    halt(if_result)
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
    Logger.error("LiveDebugger encountered unexpected error while fetching information for process: #{inspect(reason)}")

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

  defp get_root_socket_id(lv_process) when lv_process.root_pid == lv_process.pid do
    {:ok, lv_process.socket_id}
  end

  defp get_root_socket_id(lv_process) do
    lv_process.root_pid
    |> StateQueries.get_socket()
    |> case do
      {:ok, %{id: socket_id}} -> {:ok, socket_id}
      _ -> {:error, :root_socket_id_not_found}
    end
  end
end
