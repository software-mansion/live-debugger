defmodule LiveDebugger.API.SettingsStorage do
  @available_settings [
    :dead_view_mode,
    :tracing_update_on_code_reload
  ]

  @moduledoc """
  API for managing settings storage. In order to properly use invoke `init/0` at the start of application.
  It uses Erlang's DETS (Disk Erlang Term Storage) and `config` files.
  Settings are retrieved in this order:
  1. locally saved file (inside `_build/*/live_debugger/` directory)
  2. `config` files
  3. default values

  Available settings are: `#{Enum.join(@available_settings, ", ")}`.
  """

  @callback init() :: :ok
  @callback save(atom(), any()) :: :ok | {:error, term()}
  @callback get(atom()) :: any()
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

  @doc """
  List of available settings
  """
  @spec available_settings() :: [atom()]
  def available_settings(), do: @available_settings

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_settings_storage,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    alias LiveDebugger.API.SettingsStorage

    @behaviour SettingsStorage

    @default_settings %{
      dead_view_mode: true,
      tracing_update_on_code_reload: false
    }

    @table_name :lvdbg_settings
    @filename "live_debugger_saved_settings"

    @impl true
    def init() do
      {:ok, _} =
        :dets.open_file(@table_name,
          auto_save: :timer.seconds(1),
          file: file_path()
        )

      # Populate `:dets` with startup values
      get_all()
      |> Enum.each(fn {setting, value} -> save(setting, value) end)

      :ok
    end

    @impl true
    def save(setting, value) do
      :dets.insert(@table_name, {setting, value})
    end

    @impl true
    def get(setting) do
      fetch_setting(setting)
    end

    @impl true
    def get_all() do
      SettingsStorage.available_settings()
      |> Enum.map(fn setting ->
        {setting, fetch_setting(setting)}
      end)
      |> Enum.into(%{})
    end

    defp fetch_setting(setting) do
      with {:error, :not_saved} <- get_from_dets(setting),
           {:error, :not_saved} <- get_from_config(setting) do
        @default_settings[setting]
      end
    end

    defp get_from_dets(setting) do
      case :dets.lookup(@table_name, setting) do
        [{^setting, value}] ->
          value

        _ ->
          {:error, :not_saved}
      end
    end

    defp get_from_config(setting) do
      Application.get_env(:live_debugger, setting, {:error, :not_saved})
    end

    defp file_path() do
      :live_debugger
      |> Application.app_dir(@filename)
      |> String.to_charlist()
    end
  end
end
