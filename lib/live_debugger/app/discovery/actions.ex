defmodule LiveDebugger.App.Discovery.Actions do
  @moduledoc """
  Actions for the `LiveDebugger.App.Discovery` context.
  """

  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Structs.LvState

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed

  @doc """
  Removes all LiveView states associated with the given root LiveView PID.
  """
  @spec remove_lv_process_state(pid()) :: :ok
  def remove_lv_process_state(pid) when is_pid(pid) do
    StatesStorage.delete!(pid)

    StatesStorage.get_all_states()
    |> Enum.filter(fn {_, %LvState{socket: socket}} -> socket.root_pid == pid end)
    |> Enum.each(fn {pid, _} -> StatesStorage.delete!(pid) end)

    Bus.broadcast_event!(%TableTrimmed{})
  end
end
