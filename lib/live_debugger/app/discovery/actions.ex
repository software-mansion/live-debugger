defmodule LiveDebugger.App.Discovery.Actions do
  @moduledoc """
  Actions for the `LiveDebugger.App.Discovery` context.
  """

  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Structs.LvState

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.GarbageCollector.Events.TableTrimmed
  alias LiveDebugger.App.Events.UserChangedSettings

  @doc """
  Removes all LiveView states associated with the given root LiveView PID.
  """
  @spec remove_lv_process_state!(pid()) :: :ok
  def remove_lv_process_state!(pid) when is_pid(pid) do
    StatesStorage.delete!(pid)

    StatesStorage.get_all_states()
    |> Enum.filter(fn {_, %LvState{socket: socket}} -> socket.root_pid == pid end)
    |> Enum.each(fn {pid, _} -> StatesStorage.delete!(pid) end)

    Bus.broadcast_event!(%TableTrimmed{})
  end

  @spec update_dead_liveviews_setting!(boolean()) :: {:ok, boolean()} | {:error, term()}
  def update_dead_liveviews_setting!(new_value) when is_boolean(new_value) do
    case SettingsStorage.save(:dead_liveviews, new_value) do
      :ok ->
        Bus.broadcast_event!(%UserChangedSettings{
          key: :dead_liveviews,
          value: new_value,
          from: self()
        })

        {:ok, new_value}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
