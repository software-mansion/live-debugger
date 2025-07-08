defmodule LiveDebuggerRefactor.API.SettingsStorage do
  @moduledoc """
  API for managing settings storage. It uses Erlang's DETS (Disk Erlang Term Storage) and `config` files.
  If there are settings saved in `:dets` (which will be stored in `_build` directory),
  they will be used. Otherwise, values from `config` files will be used. If no option is set then default settings will be used.
  """
  alias Hex.Solver.Constraints.Impl

  @available_settings [
    :dead_view_mode,
    :tracing_update_on_code_reload
  ]

  @callback init() :: :ok
  @callback save(atom(), any()) :: :ok | {:error, term()}
  @callback get(atom()) :: any() | nil
  @callback get_all() :: map()

  @doc """
  Initializes dets table and read config values to fetch initial settings.
  It should be called when application starts.
  """
  @spec init() :: :ok
  def init(), do: impl().init()

  @doc """
  Saves a setting into the storage.
  """
  @spec save(setting :: atom(), value :: any()) :: :ok | {:error, term()}
  def save(setting, value) when setting in @available_settings do
    impl().save(setting, value)
  end

  @doc """
  Gets a setting from the storage.
  If the setting is not found, it returns default value.
  """
  @spec get(setting :: atom()) :: any()
  def get(setting) when setting in @available_settings do
    impl().get(setting)
  end

  @doc """
  Gets all settings from the storage.
  """
  @spec get_all() :: map()
  def get_all() do
    impl().get_all()
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_settings_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebuggerRefactor.API.SettingsStorage

    @impl true
    def init() do
      raise :not_implemented
    end

    @impl true
    def save(setting, value) do
      raise :not_implemented
    end

    @impl true
    def get(setting) do
      raise :not_implemented
    end

    @impl true
    def get_all() do
      raise :not_implemented
    end
  end
end
