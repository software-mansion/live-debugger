defmodule LiveDebugger.E2E.SettingsTest do
  use LiveDebugger.E2ECase

  @table_name :lvdbg_settings

  @sessions 3
  feature "all settings are working properly", %{
    sessions: [dev_app, debugger1, debugger2]
  } do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()

    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, false)
    LiveDebugger.API.SettingsStorage.save(:tracing_update_on_code_reload, false)
    LiveDebugger.API.SettingsStorage.save(:garbage_collection, false)
    LiveDebugger.API.SettingsStorage.save(:debug_button, false)
    LiveDebugger.update_live_debugger_tags()

    debugger2
    |> visit("/settings")
    |> assert_has(enable_dead_view_mode_checkbox(selected: false))
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: false))
    |> assert_has(enable_garbage_collector_checkbox(selected: false))
    |> assert_has(enable_debug_button_checkbox(selected: false))

    dev_app
    |> visit(@dev_app_url)

    # Check dead view mode toggle

    debugger1
    |> visit("/")
    |> click(first_link())
    |> assert_text("Monitored PID")

    dev_app
    |> click(link("Side"))

    Process.sleep(200)

    debugger1
    |> assert_text("Monitored PID")

    dev_app
    |> visit(@dev_app_url)

    debugger1
    |> visit("/settings")
    |> assert_has(enable_dead_view_mode_checkbox(selected: false))
    |> click(enable_dead_view_mode_toggle())
    |> assert_has(enable_dead_view_mode_checkbox(selected: true))

    debugger2
    |> assert_has(enable_dead_view_mode_checkbox(selected: true))

    assert(check_dets_for_setting(:dead_view_mode))

    debugger1
    |> visit("/")
    |> click(first_link())
    |> assert_text("Monitored PID")

    dev_app
    |> click(link("Side"))

    Process.sleep(200)

    debugger1
    |> find(css("#navbar-connected"))
    |> assert_text("Disconnected")

    # Check tracing update on reload toggle

    debugger1
    |> visit("/settings")
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: false))
    |> click(enable_tracing_update_on_reload_toggle())
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: true))

    assert(check_dets_for_setting(:tracing_update_on_code_reload))

    debugger2
    |> assert_has(enable_tracing_update_on_reload_checkbox(selected: true))

    # Check garbage collector toggle

    debugger1
    |> visit("/settings")
    |> assert_has(enable_garbage_collector_checkbox(selected: false))
    |> click(enable_garbage_collector_toggle())
    |> assert_has(enable_garbage_collector_checkbox(selected: true))

    assert(check_dets_for_setting(:garbage_collection))

    debugger2
    |> assert_has(enable_garbage_collector_checkbox(selected: true))

    # Check debug button toggle

    dev_app
    |> visit(@dev_app_url)
    |> refute_has(css("#live-debugger-debug-button"))

    debugger1
    |> visit("/settings")
    |> assert_has(enable_debug_button_checkbox(selected: false))
    |> click(enable_debug_button_toggle())
    |> assert_has(enable_debug_button_checkbox(selected: true))

    assert(check_dets_for_setting(:debug_button))

    debugger2
    |> assert_has(enable_debug_button_checkbox(selected: true))

    dev_app
    |> assert_has(css("#live-debugger-debug-button"))
    |> execute_script("window.location.reload();")
    |> assert_has(css("#live-debugger-debug-button"))

    debugger1
    |> click(enable_debug_button_toggle())

    refute(check_dets_for_setting(:debug_button))

    dev_app
    |> refute_has(css("#live-debugger-debug-button"))
    |> execute_script("window.location.reload();")
    |> refute_has(css("#live-debugger-debug-button"))
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

  defp enable_debug_button_toggle() do
    css("label:has(input[phx-value-setting=\"debug_button\"])")
  end

  defp enable_debug_button_checkbox(opts) do
    css("input[phx-value-setting=\"debug_button\"]", opts)
  end
end
