defmodule LiveDebuggerRefactor.App.Debugger.Queries.LvProcess do
  @moduledoc """
  Queries for fetching the LvProcess.
  """

  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.Structs.LvProcess
  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.API.StatesStorage

  @spec parent_lv_process(LvProcess.t()) :: LvProcess.t() | nil
  def parent_lv_process(%LvProcess{parent_pid: parent_pid}) when is_pid(parent_pid) do
    get_lv_process(parent_pid)
  end

  def parent_lv_process(_lv_process), do: nil

  @spec fetch_with_retries(pid()) :: LvProcess.t() | nil
  def fetch_with_retries(pid) when is_pid(pid) do
    with nil <- fetch_after(pid, 200),
         nil <- fetch_after(pid, 800) do
      fetch_after(pid, 1000)
    end
  end

  defp fetch_after(pid, milliseconds) when is_pid(pid) and is_integer(milliseconds) do
    Process.sleep(milliseconds)

    get_lv_process(pid)
  end

  defp get_lv_process(pid) when is_pid(pid) do
    with nil <- StatesStorage.get!(pid),
         {:error, _} <- LiveViewDebug.socket(pid) do
      nil
    else
      %LvState{socket: socket} ->
        LvProcess.new(pid, socket)

      {:ok, socket} ->
        LvProcess.new(pid, socket)
    end
  end
end
