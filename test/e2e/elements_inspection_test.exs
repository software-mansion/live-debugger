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

    dev_pid = get_dev_pid(dev_app1)

    debugger
    |> visit("/")
    |> select_live_view(dev_pid)
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

    debugger
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveComponents.Name"
      )
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

    dev_pid = get_dev_pid(dev_app1)

    debugger
    |> visit("/")
    |> select_live_view(dev_pid)
    |> click(switch_inspect_mode_button())

    dev_app1
    |> assert_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

    dev_app1
    |> refute_has(css("div.live-debugger-inspect-mode"))
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

    dev_pid = get_dev_pid(dev_app1)

    debugger
    |> visit("/")
    |> select_live_view(dev_pid)
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

    dev_pid = get_dev_pid(dev_app1)

    debugger1
    |> visit("/")
    |> select_live_view(dev_pid)
    |> click(switch_inspect_mode_button())

    debugger2
    |> visit("/")
    |> select_live_view(dev_pid)
    |> click(switch_inspect_mode_button())

    debugger3
    |> visit("/")
    |> select_live_view(dev_pid)

    dev_app1
    |> click(live_component(2))

    debugger1
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveComponents.Name"
      )
    )

    debugger2
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveComponents.Name"
      )
    )

    debugger3
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveViews.Main"
      )
    )
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
    |> hover(css("#live-sessions p.font-medium", text: "LiveDebuggerDev.LiveViews.Embedded"))
    |> click(css("#live-sessions p.font-medium", text: "LiveDebuggerDev.LiveViews.Embedded"))
    |> click(switch_inspect_mode_button())

    Process.sleep(200)

    dev_app
    |> click(
      css("div[data-phx-id=\"m1-embedded_wrapper_inner\"] span", text: "Simple [LiveView]")
    )
    |> refute_has(css("div.live-debugger-inspect-mode"))

    Process.sleep(200)

    debugger
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveViews.Simple"
      )
    )
  end

  @sessions 2
  feature "sidebar with components tree opens automatically on small screens when node is inspected",
          %{
            sessions: [dev_app, debugger]
          } do
    dev_app
    |> visit(@dev_app_url)

    dev_pid = get_dev_pid(dev_app)

    debugger
    |> resize_window(600, 1000)
    |> visit("/")
    |> select_live_view(dev_pid)

    debugger
    |> refute_has(sidebar_container())
    |> refute_has(close_button())

    debugger
    |> click(switch_inspect_mode_button())

    dev_app
    |> click(live_component(2))

    debugger
    |> assert_has(sidebar_container())
    |> assert_has(close_button())
  end

  @sessions 2
  feature "sidebar closes automatically when resized to desktop and stays closed when resized back",
          %{
            sessions: [dev_app, debugger]
          } do
    dev_app
    |> visit(@dev_app_url)

    dev_pid = get_dev_pid(dev_app)

    debugger
    |> resize_window(600, 1000)
    |> visit("/")
    |> select_live_view(dev_pid)

    debugger
    |> refute_has(sidebar_container())

    debugger
    |> click(switch_inspect_mode_button())

    dev_app
    |> click(live_component(2))

    debugger
    |> assert_has(sidebar_container())
    |> assert_has(close_button())

    debugger
    |> resize_window(1200, 1000)
    |> resize_window(600, 1000)

    debugger
    |> refute_has(sidebar_container())
    |> refute_has(close_button())
  end

  defp close_button(), do: css("button[phx-click=\"close-sidebar\"]")
  defp sidebar_container(), do: css("#components-tree-sidebar-container")
end
