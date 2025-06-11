defmodule LiveDebugger.GenServers.SettingsServer do
  @moduledoc """
  This agent is used for storing application settings.
  It saves changes in file to remember between runs.
  """

  @table_name :live_debugger_settings

  use GenServer

  @settings [:dead_view_mode, :tracing_update_on_code_reload]

  ## API

  @spec get(setting :: atom()) :: term()
  def get(setting) when setting in @settings do
    GenServer.call(__MODULE__, {:get, setting})
  end

  @spec get_all() :: map()
  def get_all() do
    GenServer.call(__MODULE__, :get_all)
  end

  @spec save(setting :: atom(), value :: term()) :: :ok | {:error, term()}
  def save(setting, value) when setting in @settings do
    GenServer.cast(__MODULE__, {:save, setting, value})
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
    save_in_dets(setting, value)

    {:noreply, Map.put(state, setting, value)}
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
    Application.app_dir(:live_debugger)
    |> Path.join("live_debugger_settings")
    |> String.to_charlist()
  end
end
