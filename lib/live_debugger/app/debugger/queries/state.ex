defmodule LiveDebugger.App.Debugger.Queries.State do
  @moduledoc """
  Queries for fetching the LiveView state information using the `StatesStorage` and `LiveViewDebug` modules.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.Structs.LvState

  @spec get_lv_state(pid()) :: {:ok, LvState.t()} | {:error, term()}
  def get_lv_state(pid) when is_pid(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end

  @spec get_socket(pid()) :: {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}
  def get_socket(pid) do
    case StatesStorage.get!(pid) do
      %LvState{socket: socket} -> {:ok, socket}
      nil -> LiveViewDebug.socket(pid)
    end
  end
end
