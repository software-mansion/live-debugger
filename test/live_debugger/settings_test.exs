defmodule LiveDebugger.SettingsTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "all settings are working properly", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    LiveDebugger.GenServers.SettingsServer.save(:dead_view_mode, false)
    LiveDebugger.GenServers.SettingsServer.save(:tracing_update_on_code_reload, false)

    dev_app
    |> visit(@dev_app_url)

    # Check themes

    debugger
    |> visit("/settings")
    |> assert_has(title(text: "Settings"))

    debugger
    |> assert_has(css("html[class=dark]"))
    |> assert_has(light_mode_switch())
    |> click(light_mode_switch())
    |> assert_has(css("html[class]"))
    |> assert_has(dark_mode_switch())
    |> click(dark_mode_switch())
    |> assert_has(css("html[class=dark]"))

    # Check dead view mode toggle

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(dead_view_monitored_pid())

    dev_app
    |> click(button("Crash"))

    debugger
    |> assert_has(dead_view_monitored_pid())

    debugger
    |> visit("/settings")
    |> assert_has(enable_dead_view_mode_checkbox(selected: false))
    |> click(enable_dead_view_mode_toggle())
    |> assert_has(enable_dead_view_mode_checkbox(selected: true))

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(dead_view_monitored_pid())

    dev_app
    |> click(button("Crash"))

    debugger
    |> assert_has(dead_view_disconnected())
  end

  defp dark_mode_switch() do
    css("#dark-mode-switch")
  end

  defp light_mode_switch() do
    css("#light-mode-switch")
  end

  defp enable_dead_view_mode_toggle() do
    css("label:has(input[phx-value-setting=dead_view_mode])")
  end

  defp enable_dead_view_mode_checkbox(opts) do
    css("input[phx-value-setting=dead_view_mode]", opts)
  end

  defp dead_view_monitored_pid() do
    Wallaby.Query.text("Monitored PID")
  end

  defp dead_view_disconnected() do
    Wallaby.Query.text("Disconnected")
  end
end
