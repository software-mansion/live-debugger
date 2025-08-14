defmodule LiveDebugger.E2E.SettingsTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "all settings are working properly", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManager.ping!()

    LiveDebuggerRefactor.API.SettingsStorage.save(:dead_view_mode, false)
    LiveDebuggerRefactor.API.SettingsStorage.save(:tracing_update_on_code_reload, false)

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
end
