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

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) when is_pid(pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn -> LvProcessQueries.get_lv_process(pid) end)
  end

  defp handle_async(:lv_process, {:ok, %LvProcess{} = lv_process}, socket) do
    socket
    |> assign(:lv_process, AsyncResult.ok(lv_process))
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
end
