defmodule LiveDebugger.GenServers.ChannelStateServer do
  @moduledoc """
  This gen_server is responsible for saving and retrieving the state of LiveView processes.
  It uses ETS tables to store the state of each LiveView process.
  """
  use GenServer

  alias LiveDebugger.Services.System.ProcessService
  alias LiveDebugger.CommonTypes

  @table_prefix "lvdbg-states"

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec save_state(pid :: pid()) :: :ok
  def save_state(pid) when is_pid(pid) do
    timestamp = :os.system_time(:microsecond)
    GenServer.cast(__MODULE__, {:save_state, pid, timestamp})
  end

  @spec get_state(pid :: pid()) ::
          {:ok, CommonTypes.channel_state()} | {:error, term()}
  def get_state(pid) when is_pid(pid) do
    GenServer.call(__MODULE__, {:get_state, pid})
  end

  @impl true
  def init(_args) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:save_state, pid, timestamp}, counters) do
    counters =
      if Map.has_key?(counters, pid) do
        counters
      else
        pid |> ets_table_id() |> init_table()
        Map.put(counters, pid, 0)
      end

    counters =
      case ProcessService.state(pid) do
        {:ok, channel_state} ->
          pid
          |> ets_table_id()
          |> :ets.insert({timestamp, channel_state})

          Map.update!(counters, pid, &(&1 + 1))

        {:error, _} ->
          counters
      end

    {:noreply, counters}
  end

  @impl true
  def handle_call({:get_state, pid}, _from, counters) do
    reply =
      if counters[pid] && counters[pid] > 0 do
        table_id = ets_table_id(pid)
        key = :ets.last(table_id)

        case :ets.lookup(table_id, key) do
          [{_, channel_state}] -> {:ok, channel_state}
          _ -> {:error, :no_state_found}
        end
      else
        {:error, :no_state_recorded}
      end

    {:reply, reply, counters}
  end

  defp init_table(table_id) do
    :ets.new(table_id, [:ordered_set, :public, :named_table])
  end

  defp ets_table_id(pid) do
    String.to_atom("#{@table_prefix}-#{inspect(pid)}")
  end
end
