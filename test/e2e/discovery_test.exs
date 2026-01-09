defmodule LiveDebugger.E2E.DiscoveryTest do
  use LiveDebugger.E2ECase

  @sessions 3
  feature "user can see active live views and their highlights which are refreshed automatically",
          %{
            sessions: [dev_app1, dev_app2, debugger]
          } do
    dev_app1
    |> visit(@dev_app_url)

    dev_pid1 = get_dev_pid(dev_app1)

    debugger
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))

    dev_app2
    |> visit(@dev_app_url)

    dev_pid2 = get_dev_pid(dev_app2)

    Process.sleep(200)

    debugger
    |> assert_has(live_sessions(count: 2))
    |> hover(live_view_button(dev_pid1))

    dev_app1
    |> assert_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveViews.Main"))
    |> assert_has(inspect_tooltip_type_text("LiveView"))

    dev_app2
    |> refute_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveViews.Main"))
    |> refute_has(inspect_tooltip_type_text("LiveView"))

    debugger
    |> hover(live_view_button(dev_pid2))

    dev_app1
    |> refute_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveViews.Main"))
    |> refute_has(inspect_tooltip_type_text("LiveView"))

    dev_app2
    |> assert_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveViews.Main"))
    |> assert_has(inspect_tooltip_type_text("LiveView"))
  end

  @sessions 2
  feature "settings button exists and redirects works as expected", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(settings_button())
    |> click(settings_button())
    |> assert_has(title(text: "Settings"))
    |> assert_has(return_button())
    |> click(return_button())
    |> assert_has(title(text: "Active LiveViews"))
  end
end
