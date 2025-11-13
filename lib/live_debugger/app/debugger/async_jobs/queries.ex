defmodule LiveDebugger.App.Debugger.AsyncJobs.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.AsyncJobs` context.
  """

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage

  @spec fetch_node_state(pid()) :: {:ok, LvState.t()} | {:error, term()}
  def fetch_node_state(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end
end
