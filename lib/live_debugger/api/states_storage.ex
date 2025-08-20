defmodule LiveDebugger.API.StatesStorage do
  @moduledoc """
  API for storing LiveView's states in memory.
  In oder to properly use this API, invoke `init/0` at the start of application.
  It uses Erlang's ETS (Erlang Term Storage) under the hood.
  """

  alias LiveDebugger.Structs.LvState

  @callback init() :: :ok
  @callback save!(LvState.t()) :: true
  @callback get!(pid()) :: LvState.t() | nil
  @callback delete!(pid()) :: true
  @callback get_all_states() :: [{pid(), LvState.t()}]
  @callback get_states_table() :: :ets.table()

  @doc """
  Initializes empty ets table.
  It should be called when application starts.
  """
  @spec init() :: :ok
  def init(), do: impl().init()

  @doc """
  Saves `#{LvState}` using `pid` as key.
  """
  @spec save!(LvState.t()) :: true
  def save!(%LvState{} = state), do: impl().save!(state)

  @doc """
  Retrieves saved state for `pid`.
  If nothing is stored it returns `nil`.
  """
  @spec get!(pid()) :: LvState.t() | nil
  def get!(pid) when is_pid(pid), do: impl().get!(pid)

  @doc """
  Deletes saved state for `pid`.
  """
  @spec delete!(pid()) :: true
  def delete!(pid) when is_pid(pid), do: impl().delete!(pid)

  @doc """
  Retrieves all saved states.
  """
  @spec get_all_states() :: [{pid(), LvState.t()}]
  def get_all_states(), do: impl().get_all_states()

  @doc """
  Retrieves states table reference.
  """
  @spec get_states_table() :: :ets.table()
  def get_states_table(), do: impl().get_states_table()

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_states_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.StatesStorage

    @table_name :lvdbg_states

    @impl true
    def init() do
      case :ets.whereis(@table_name) do
        :undefined ->
          :ets.new(@table_name, [:ordered_set, :public, :named_table])

        _ref ->
          :ets.delete_all_objects(@table_name)
      end

      :ok
    end

    @impl true
    def save!(%LvState{pid: pid} = state) do
      :ets.insert(@table_name, {pid, state})
    end

    @impl true
    def get!(pid) do
      case :ets.lookup(@table_name, pid) do
        [{^pid, state}] ->
          state

        _ ->
          nil
      end
    end

    @impl true
    def delete!(pid) do
      :ets.delete(@table_name, pid)
    end

    @impl true
    def get_all_states(), do: :ets.tab2list(@table_name)

    @impl true
    def get_states_table(), do: @table_name
  end
end
