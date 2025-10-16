defmodule LiveDebugger.E2E.ElementsInspectionTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can inspect elements after enabling inspect mode from LiveDebugger", %{
    sessions: [dev_app1, debugger]
  } do
    LiveDebugger.API.SettingsStorage.save(:debug_button, true)
    LiveDebugger.update_live_debugger_tags()

    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(switch_inspect_mode_button())

    dev_app1
    |> assert_has(css("div.live-debugger-inspect-mode"))
    |> hover(live_component(2))

    Process.sleep(400)

    dev_app1
    |> assert_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveComponents.Name"))
    |> assert_has(inspect_tooltip_type_text("LiveComponent"))
    |> assert_has(inspect_tooltip_value_text("2"))

    dev_app1
    |> click(live_component(2))
    |> refute_has(css("div.live-debugger-inspect-mode"))

    assert_has(
      debugger,
      css("#node-inspector-basic-info-current-node-module", text: "LiveDebuggerDev.LiveComponents.Name")
    )
  end

  @sessions 2
  feature "user can disable inspect mode from LiveDebugger", %{
    sessions: [dev_app1, debugger]
  } do
    LiveDebugger.API.SettingsStorage.save(:debug_button, true)
    LiveDebugger.update_live_debugger_tags()

    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(switch_inspect_mode_button())

    assert_has(dev_app1, css("div.live-debugger-inspect-mode"))
    click(debugger, css("button[phx-click=\"switch-inspect-mode\"]"))
    refute_has(dev_app1, css("div.live-debugger-inspect-mode"))
  end

  @sessions 2
  feature "user can disable inspect mode by right clicking in debugged window", %{
    sessions: [dev_app1, debugger]
  } do
    LiveDebugger.API.SettingsStorage.save(:debug_button, true)
    LiveDebugger.update_live_debugger_tags()

    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(switch_inspect_mode_button())

    dev_app1
    |> assert_has(css("div.live-debugger-inspect-mode"))
    |> click(:right)
    |> refute_has(css("div.live-debugger-inspect-mode"))
  end

  @sessions 4
  feature "selecting node redirects all debugger windows that are subscribed to it", %{
    sessions: [dev_app1, debugger1, debugger2, debugger3]
  } do
    LiveDebugger.API.SettingsStorage.save(:debug_button, true)
    LiveDebugger.update_live_debugger_tags()

    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger1
    |> visit("/")
    |> click(first_link())
    |> click(switch_inspect_mode_button())

    debugger2
    |> visit("/")
    |> click(first_link())
    |> click(switch_inspect_mode_button())

    debugger3
    |> visit("/")
    |> click(first_link())

    click(dev_app1, live_component(2))

    assert_has(
      debugger1,
      css("#node-inspector-basic-info-current-node-module", text: "LiveDebuggerDev.LiveComponents.Name")
    )

    assert_has(
      debugger2,
      css("#node-inspector-basic-info-current-node-module", text: "LiveDebuggerDev.LiveComponents.Name")
    )

    assert_has(debugger3, css("#node-inspector-basic-info-current-node-module", text: "LiveDebuggerDev.LiveViews.Main"))
  end

  @sessions 2
  feature "inspection works for LiveViews nested in LiveComponents", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url <> "/embedded")
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(css("#live-sessions p.font-medium", text: "LiveDebuggerDev.LiveViews.Embedded"))
    |> click(switch_inspect_mode_button())

    Process.sleep(200)

    dev_app
    |> click(css("div[data-phx-id=\"m1-embedded_wrapper_inner\"] span", text: "Simple [LiveView]"))
    |> refute_has(css("div.live-debugger-inspect-mode"))

    Process.sleep(200)

    assert_has(debugger, css("#node-inspector-basic-info-current-node-module", text: "LiveDebuggerDev.LiveViews.Simple"))
  end
end
