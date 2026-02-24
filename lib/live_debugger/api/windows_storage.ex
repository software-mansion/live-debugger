defmodule LiveDebugger.API.WindowsStorage do
  @moduledoc """
  API for storing fingerprint -> windowId mappings in memory.
  In order to properly use this API, invoke `init/0` at the start of application.
  It uses Erlang's ETS (Erlang Term Storage) under the hood.
  """

  alias LiveDebugger.Structs.LvProcess

  @callback init() :: :ok
  @callback save!(fingerprint :: term(), window_id :: term()) :: true
  @callback get_window_id!(fingerprint :: term()) :: term() | nil
  @callback delete!(fingerprint :: term()) :: true
  @callback delete_by_window_id!(window_id :: term()) :: non_neg_integer()

  @doc """
  Initializes empty ETS table.
  It should be called when application starts.
  """
  @spec init() :: :ok
  def init(), do: impl().init()

  @doc """
  Saves mapping of `fingerprint` to `window_id`.
  Overwrites existing entry if fingerprint already exists.
  """
  @spec save!(term(), term()) :: true
  def save!(fingerprint, window_id), do: impl().save!(fingerprint, window_id)

  @doc """
  Retrieves window_id for given `fingerprint`.
  Returns `nil` if no mapping exists.
  """
  @spec get_window_id!(term()) :: term() | nil
  def get_window_id!(fingerprint), do: impl().get_window_id!(fingerprint)

  @doc """
  Deletes the mapping for given `fingerprint`.
  """
  @spec delete!(term()) :: true
  def delete!(fingerprint), do: impl().delete!(fingerprint)

  @doc """
  Deletes all mappings for given `window_id`.
  Returns the number of deleted entries.
  """
  @spec delete_by_window_id!(term()) :: non_neg_integer()
  def delete_by_window_id!(window_id), do: impl().delete_by_window_id!(window_id)

  @doc """
  Creates a fingerprint from a list of `lv_processes`.
  """
  @spec create_fingerprint([LvProcess.t()]) :: String.t()
  def create_fingerprint(lv_processes) do
    lv_processes
    |> Enum.map(fn lv_process -> lv_process.socket_id end)
    |> Enum.sort()
    |> Enum.join(";")
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_windows_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.WindowsStorage

    @table_name :lvdbg_windows

    @impl true
    def init() do
      case :ets.whereis(@table_name) do
        :undefined ->
          :ets.new(@table_name, [:set, :public, :named_table])

        _ref ->
          :ets.delete_all_objects(@table_name)
      end

      :ok
    end

    @impl true
    def save!(fingerprint, window_id) do
      :ets.insert(@table_name, {fingerprint, window_id})
    end

    @impl true
    def get_window_id!(fingerprint) do
      case :ets.lookup(@table_name, fingerprint) do
        [{^fingerprint, window_id}] ->
          window_id

        _ ->
          nil
      end
    end

    @impl true
    def delete!(fingerprint) do
      :ets.delete(@table_name, fingerprint)
    end

    @impl true
    def delete_by_window_id!(window_id) do
      :ets.select_delete(@table_name, [{{:_, :"$1"}, [{:"=:=", :"$1", window_id}], [true]}])
    end
  end
end
