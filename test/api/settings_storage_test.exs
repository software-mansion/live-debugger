defmodule LiveDebugger.API.SettingsStorageTest do
  # Not async: these tests exercise the real `Impl`, which relies on a shared
  # named ETS table, a fixed persisted file and the application environment.
  use ExUnit.Case, async: false

  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.API.SettingsStorage.Impl

  @table_name :lvdbg_settings
  @filename "live_debugger_saved_settings"

  setup do
    settings = SettingsStorage.available_settings()

    # Snapshot and restore the global state each test mutates so runs stay
    # isolated (config values, the persisted file and the ETS table contents).
    env_backup =
      Map.new(settings, fn setting ->
        {setting, Application.fetch_env(:live_debugger, setting)}
      end)

    file_backup = File.read(file_path())

    Enum.each(settings, &Application.delete_env(:live_debugger, &1))
    File.rm(file_path())

    if :ets.whereis(@table_name) != :undefined do
      :ets.delete_all_objects(@table_name)
    end

    on_exit(fn ->
      Enum.each(env_backup, fn
        {setting, {:ok, value}} -> Application.put_env(:live_debugger, setting, value)
        {setting, :error} -> Application.delete_env(:live_debugger, setting)
      end)

      case file_backup do
        {:ok, binary} -> File.write!(file_path(), binary)
        {:error, _} -> File.rm(file_path())
      end
    end)

    :ok
  end

  describe "init/0 value precedence" do
    test "creates the settings table" do
      assert :ok = Impl.init()

      assert is_reference(:ets.whereis(@table_name))
    end

    test "uses default values when nothing is configured or saved" do
      assert :ok = Impl.init()

      assert Impl.get(:dead_view_mode) == true
      assert Impl.get(:dead_liveviews) == false
    end

    test "prefers a saved value over the default" do
      write_saved(%{dead_view_mode: :from_saved})

      assert :ok = Impl.init()

      assert Impl.get(:dead_view_mode) == :from_saved
      # A setting missing from the saved file still falls back to its default.
      assert Impl.get(:garbage_collection) == true
    end

    test "prefers a config value over both the saved value and the default" do
      write_saved(%{dead_view_mode: :from_saved})
      Application.put_env(:live_debugger, :dead_view_mode, :from_config)

      assert :ok = Impl.init()

      assert Impl.get(:dead_view_mode) == :from_config
    end
  end

  describe "persistence across restarts" do
    test "save/2 writes the setting to the persisted file" do
      assert :ok = Impl.init()

      assert :ok = Impl.save(:highlight_in_browser, false)

      assert File.exists?(file_path())
      assert read_saved()[:highlight_in_browser] == false
    end

    test "saved values are reloaded after a restart" do
      assert :ok = Impl.init()
      assert :ok = Impl.save(:dead_view_mode, false)

      # Simulate a fresh VM: drop in-memory state but keep the persisted file.
      :ets.delete_all_objects(@table_name)

      assert :ok = Impl.init()

      assert Impl.get(:dead_view_mode) == false
      assert Impl.get(:garbage_collection) == true
    end
  end

  describe "decoding of corrupt or legacy persisted data" do
    test "falls back to defaults when the file is not a valid term (e.g. a leftover DETS file)" do
      File.write!(file_path(), <<0, 1, 2, "not an erlang term", 255>>)

      assert :ok = Impl.init()

      assert Impl.get(:dead_view_mode) == true
      assert Impl.get(:dead_liveviews) == false
    end

    test "falls back to defaults when the persisted term is not a map" do
      File.write!(file_path(), :erlang.term_to_binary([1, 2, 3]))

      assert :ok = Impl.init()

      assert Impl.get(:garbage_collection) == true
    end
  end

  defp file_path(), do: Application.app_dir(:live_debugger, @filename)

  defp write_saved(map), do: File.write!(file_path(), :erlang.term_to_binary(map))

  defp read_saved(), do: file_path() |> File.read!() |> :erlang.binary_to_term([:safe])
end
