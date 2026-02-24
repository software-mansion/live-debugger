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
  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.DebuggerMounted

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn ->
      LvProcessQueries.get_lv_process_with_retries_and_window_id(pid)
    end)
  end

  defp handle_async(:lv_process, {:ok, %LvProcess{} = lv_process}, socket) do
    Bus.broadcast_event!(%DebuggerMounted{
      debugger_pid: self(),
      debugged_pid: lv_process.pid
    })

    socket
    |> assign(:lv_process, AsyncResult.ok(lv_process))
    |> halt()
  end

  defp handle_async(:lv_process, {:ok, nil}, socket) do
    socket
    |> put_flash(:error, "LiveView process not found")
    |> push_navigate(to: RoutesHelper.discovery())
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
end
