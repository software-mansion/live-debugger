defmodule LiveDebugger.E2E.LiveViewsDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 3
  feature "user can see active live views which are refreshed automatically", %{
    sessions: [dev_app1, dev_app2, debugger]
  } do
    dev_app1
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))

    dev_app2
    |> visit(@dev_app_url)

    debugger
    |> assert_has(live_sessions(count: 2))
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
