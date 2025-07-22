defmodule LiveDebuggerRefactor.Services.StateManager.Actions do
  @moduledoc """
  Actions responsible for saving LiveView process' state.
  """

  alias LiveDebuggerRefactor.API.StatesStorage
  alias LiveDebuggerRefactor.API.LiveViewDebug

  @doc """
  Fetches state of the given LiveView's `pid` and saves it to the storage.
  If the state cannot be fetched, it returns an error tuple.
  """
  @spec save_state!(pid()) :: :ok | {:error, term()}
  def save_state!(pid) when is_pid(pid) do
    with {:ok, lv_state} <- LiveViewDebug.liveview_state(pid) do
      StatesStorage.save!(lv_state)
      :ok
    end
  end
end
