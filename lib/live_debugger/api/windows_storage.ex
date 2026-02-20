defmodule LiveDebugger.API.WindowsStorage do
  @moduledoc """
  API for storing fingerprint -> windowId mappings in memory.
  In order to properly use this API, invoke `init/0` at the start of application.
  It uses Erlang's ETS (Erlang Term Storage) under the hood.
  """

  @callback init() :: :ok
  @callback save!(fingerprint :: term(), window_id :: term()) :: true
  @callback get_window_id!(fingerprint :: term()) :: term() | nil
  @callback delete!(fingerprint :: term()) :: true

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
  end
end
