defmodule LiveDebuggerRefactor.App.Debugger.Web.Hooks.AsyncLvProcess do
  @moduledoc """
  Hooks for asynchronous LVProcess assignment.
  """

  require Logger

  use LiveDebuggerRefactor.App.Web, :hook

  alias LiveDebuggerRefactor.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.App.Web.Helpers.Routes, as: RoutesHelper
  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.DebuggerMounted

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn -> LvProcessQueries.get_lv_process_with_retries(pid) end)
  end

  defp handle_async(:lv_process, {:ok, %LvProcess{} = lv_process}, socket) do
    Bus.broadcast_event!(%DebuggerMounted{
      debugger_pid: self(),
      debugged_pid: lv_process.pid
    })

    socket
    |> assign(:lv_process, AsyncResult.ok(lv_process))
    |> assign_root_socket_id(lv_process)
    |> halt()
  end

  defp handle_async(:lv_process, {:ok, nil}, socket) do
    socket
    |> push_navigate(to: RoutesHelper.error("not_found"))
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

  defp assign_root_socket_id(socket, lv_process) do
    if lv_process.root_pid == lv_process.pid do
      assign(socket, :root_socket_id, lv_process.socket_id)
    else
      lv_process.root_pid
      |> LiveViewDebug.socket()
      |> case do
        {:ok, %{id: socket_id}} ->
          assign(socket, :root_socket_id, socket_id)

        _ ->
          assign(socket, :root_socket_id, nil)
      end
    end
  end
end
