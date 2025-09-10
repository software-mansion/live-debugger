defmodule LiveDebugger.E2E.SettingsTest do
  use LiveDebugger.E2ECase

  @sessions 2
  @table_name :lvdbg_settings

  feature "all settings are working properly", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()

    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, false)
    LiveDebugger.API.SettingsStorage.save(:tracing_update_on_code_reload, false)
    LiveDebugger.API.SettingsStorage.save(:garbage_collection, false)

    dev_app
    |> visit(@dev_app_url)

    # Check dead view mode toggle

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_text("Monitored PID")

    dev_app
    |> click(link("Side"))

    Process.sleep(200)

    debugger
    |> assert_text("Monitored PID")

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/settings")
    |> assert_has(enable_dead_view_mode_checkbox(selected: false))
    |> click(enable_dead_view_mode_toggle())
    |> assert_has(enable_dead_view_mode_checkbox(selected: true))

    assert(check_dets_for_setting(:dead_view_mode))

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_text("Monitored PID")

    dev_app
    |> click(link("Side"))

    Process.sleep(200)

    debugger
    |> find(css("#navbar-connected"))
    |> assert_text("Disconnected")

    # Check tracing update on reload toggle

    debugger
    |> visit("/settings")
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: false))
    |> click(enable_tracing_update_on_reload_toggle())
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: true))

    assert(check_dets_for_setting(:tracing_update_on_code_reload))

    debugger
    |> visit("/settings")
    |> assert_has(enable_garbage_collector_checkbox(selected: false))
    |> click(enable_garbage_collector_toggle())
    |> assert_has(enable_garbage_collector_checkbox(selected: true))

    assert(check_dets_for_setting(:garbage_collection))
  end

  defp check_dets_for_setting(setting) do
    case :dets.lookup(@table_name, setting) do
      [{^setting, value}] -> value
      _ -> nil
    end
  end

  defp enable_dead_view_mode_toggle() do
    css("label:has(input[phx-value-setting=\"dead_view_mode\"])")
  end

  defp enable_dead_view_mode_checkbox(opts) do
    css("input[phx-value-setting=\"dead_view_mode\"]", opts)
  end

  defp enable_tracing_update_on_reload_toggle() do
    css("label:has(input[phx-value-setting=\"tracing_update_on_code_reload\"])")
  end

  defp enable_tracing_update_on_reload_checkbox(opts) do
    css("input[phx-value-setting=\"tracing_update_on_code_reload\"]", opts)
  end

  defp enable_garbage_collector_toggle() do
    css("label:has(input[phx-value-setting=\"garbage_collection\"])")
  end

  defp enable_garbage_collector_checkbox(opts) do
    css("input[phx-value-setting=\"garbage_collection\"]", opts)
  end
end
