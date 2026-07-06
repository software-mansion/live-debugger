defmodule LiveDebugger.API.SettingsStorage do
  @available_settings [
    :dead_view_mode,
    :garbage_collection,
    :debug_button,
    :tracing_enabled_on_start,
    :dead_liveviews,
    :highlight_in_browser
  ]

  @moduledoc """
  API for managing settings storage. In order to properly use invoke `init/0` at the start of application.
  Settings are kept in an ETS table for fast access and persisted to a file
  (inside `_build/*/live_debugger/`) so they survive application restarts.
  On `init/0` each setting value is resolved with the following precedence:
  1. value set in the application config (`config :live_debugger, <setting>, ...`)
  2. value persisted to the local file (inside `_build/*/live_debugger/` directory)
  3. default value

  Only values changed at runtime via `save/2` are persisted, so a value set in
  config keeps taking precedence on every application start.

  Available settings are: `#{Enum.join(@available_settings, ", ")}`.
  """

  @callback init() :: :ok
  @callback save(atom(), any()) :: :ok | {:error, term()}
  @callback get(atom()) :: any()
  @callback get_all() :: map()

  @doc """
  Initializes the settings table and reads config values to fetch initial settings.
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
      garbage_collection: true,
      debug_button: true,
      tracing_enabled_on_start: true,
      dead_liveviews: false,
      highlight_in_browser: true
    }

    @table_name :lvdbg_settings
    @filename "live_debugger_saved_settings"

    @impl true
    def init() do
      ensure_table!()

      saved = load_saved()

      # On init we resolve every setting in the following order:
      # 1. value set in the application config, if any, is always prioritized
      # 2. otherwise the value persisted from a previous session is used
      # 3. otherwise the default value is used
      #
      # Only values explicitly changed at runtime via `save/2` are persisted,
      # so a value set in config keeps winning on every application start.
      SettingsStorage.available_settings()
      |> Enum.each(fn setting ->
        value =
          Application.get_env(
            :live_debugger,
            setting,
            Map.get(saved, setting, @default_settings[setting])
          )

        :ets.insert(@table_name, {setting, value})
      end)

      :ok
    end

    @impl true
    def save(setting, value) do
      :ets.insert(@table_name, {setting, value})
      persist()
    end

    @impl true
    def get(setting) do
      case table_lookup(setting) do
        {:ok, value} -> value
        :error -> @default_settings[setting]
      end
    end

    @impl true
    def get_all() do
      SettingsStorage.available_settings()
      |> Enum.map(fn setting -> {setting, get(setting)} end)
      |> Enum.into(%{})
    end

    defp ensure_table!() do
      case :ets.whereis(@table_name) do
        :undefined -> :ets.new(@table_name, [:set, :public, :named_table])
        _ref -> @table_name
      end
    end

    defp table_lookup(setting) do
      case :ets.whereis(@table_name) do
        :undefined ->
          :error

        _ref ->
          case :ets.lookup(@table_name, setting) do
            [{^setting, value}] -> {:ok, value}
            _ -> :error
          end
      end
    end

    # Persists the whole settings table to a plain term file. A plain file has
    # no "open/dirty" flag (unlike DETS), so an abrupt VM halt can never leave
    # it in a state that triggers a repair on the next start.
    defp persist() do
      @table_name
      |> :ets.tab2list()
      |> Map.new()
      |> write_file()
    end

    defp write_file(map) do
      path = file_path()
      tmp = path <> ".tmp." <> Integer.to_string(:erlang.unique_integer([:positive]))

      with :ok <- File.write(tmp, :erlang.term_to_binary(map)),
           :ok <- rename_over(tmp, path) do
        :ok
      else
        {:error, reason} ->
          _ = File.rm(tmp)
          {:error, reason}
      end
    end

    # `File.rename/2` does not overwrite an existing destination on all
    # platforms (notably on Windows it returns `{:error, :eexist}`), which would
    # make every `save/2` after the first one fail and silently stop persisting.
    # Remove the stale file and retry so persistence keeps working across saves.
    defp rename_over(tmp, path) do
      case File.rename(tmp, path) do
        {:error, :eexist} ->
          with :ok <- File.rm(path) do
            File.rename(tmp, path)
          end

        other ->
          other
      end
    end

    defp load_saved() do
      case File.read(file_path()) do
        {:ok, binary} -> decode(binary)
        {:error, _reason} -> %{}
      end
    end

    defp decode(binary) do
      case :erlang.binary_to_term(binary, [:safe]) do
        map when is_map(map) -> map
        _ -> %{}
      end
    rescue
      _ -> %{}
    end

    defp file_path() do
      Application.app_dir(:live_debugger, @filename)
    end
  end
end
