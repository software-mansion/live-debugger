defmodule LiveDebuggerRefactor.App.Debugger.Web.Hooks.AsyncLvProcess do
  @moduledoc """
  Hooks for asynchronous LVProcess assignment.
  """

  use LiveDebuggerRefactor.App.Web, :hook

  alias LiveDebuggerRefactor.App.Debugger.Queries.LvProcess, as: LvProcessQueries
  alias Phoenix.LiveView.AsyncResult

  @spec init(Phoenix.LiveView.Socket.t(), pid()) :: Phoenix.LiveView.Socket.t()
  def init(socket, pid) when is_pid(pid) do
    socket
    |> attach_hook(:async_lv_process, :handle_async, &handle_async/3)
    |> register_hook(:async_lv_process)
    |> assign(:lv_process, AsyncResult.loading())
    |> start_async(:lv_process, fn -> LvProcessQueries.fetch_with_retries(pid) end)
  end

  defp handle_async(:lv_process, {:ok, lv_process}, socket) do
    socket
    |> assign(:lv_process, AsyncResult.ok(lv_process))
    |> halt()
  end

  defp handle_async(:lv_process, _, socket) do
    socket
    |> assign(:lv_process, AsyncResult.failed(socket.assigns.lv_process, :not_found))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}
end
