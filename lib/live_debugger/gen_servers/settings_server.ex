defmodule LiveDebugger.GenServers.SettingsServer do
  @settings [:dead_view_mode, :tracing_update_on_code_reload]

  @moduledoc """
  This agent is used for storing application settings.
  It saves changes in file to remember between runs by using DETS (Disk Erlang Term Storage).
  Settings will be saved in `_build` directory of the application.

  The settings are: `#{Enum.join(@settings, ", ")}`.
  """

  @table_name :live_debugger_settings

  use GenServer

  alias LiveDebugger.GenServers.CallbackTracingServer

  ## API

  @callback get(setting :: atom()) :: term()
  @callback get_all() :: map()
  @callback save(setting :: atom(), value :: term()) :: :ok | {:error, term()}

  @doc """
  Retrieves the value of a specific setting.
  """
  @spec get(setting :: atom()) :: term()
  def get(setting) when setting in @settings, do: impl().get(setting)

  @doc """
  Retrieves all settings as a map.
  """
  @spec get_all() :: map()
  def get_all(), do: impl().get_all()

  @doc """
  Saves a setting with the given value.
  """
  @spec save(setting :: atom(), value :: term()) :: :ok | {:error, term()}
  def save(setting, value) when setting in @settings do
    impl().save(setting, value)
  end

  ## GenServer

  @doc false
  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_args) do
    {:ok, _} =
      :dets.open_file(@table_name,
        auto_save: :timer.seconds(1),
        file: file_path()
      )

    state =
      @settings
      |> Enum.map(fn setting -> {setting, fetch_setting(setting)} end)
      |> Enum.into(%{})

    {:ok, state}
  end

  @impl true
  def handle_call({:get, setting}, _from, state) do
    {:reply, Map.get(state, setting), state}
  end

  @impl true
  def handle_call(:get_all, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast({:save, setting, value}, state) do
    dbg({setting, value})
    save_in_dets(setting, value)

    case {setting, value} do
      {:tracing_update_on_code_reload, true} ->
        CallbackTracingServer.add_code_reload_tracing()

      {:tracing_update_on_code_reload, false} ->
        CallbackTracingServer.remove_code_reload_tracing()

      _ ->
        nil
    end

    {:noreply, Map.put(state, setting, value)}
  end

  defp impl() do
    Application.get_env(:live_debugger, :settings_server, __MODULE__.Impl)
  end

  defmodule Impl do
    @moduledoc false

    @behaviour LiveDebugger.GenServers.SettingsServer
    @server_module LiveDebugger.GenServers.SettingsServer

    @impl true
    def get(setting) do
      GenServer.call(@server_module, {:get, setting})
    end

    @impl true
    def get_all() do
      GenServer.call(@server_module, :get_all)
    end

    @impl true
    def save(setting, value) do
      GenServer.cast(@server_module, {:save, setting, value})
    end
  end

  defp fetch_setting(setting) when setting in @settings do
    with {:error, nil} <- get_from_dets(setting),
         {:error, nil} <- Application.get_env(:live_debugger, setting, {:error, nil}) do
      default_setting(setting)
    end
  end

  defp save_in_dets(setting, value) when setting in @settings do
    :dets.insert(@table_name, {setting, value})
  end

  defp get_from_dets(setting) when setting in @settings do
    case :dets.lookup(@table_name, setting) do
      [{^setting, value}] ->
        value

      _ ->
        {:error, nil}
    end
  end

  defp default_setting(:dead_view_mode), do: true
  defp default_setting(:tracing_update_on_code_reload), do: false

  defp file_path() do
    :live_debugger
    |> Application.app_dir()
    |> Path.join("live_debugger_settings")
    |> String.to_charlist()
  end
end
