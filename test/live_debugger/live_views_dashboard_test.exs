defmodule LiveDebugger.LiveViewsDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 3
  feature "user can see active live views and refresh to see more", %{
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
    |> assert_has(live_sessions(count: 1))
    |> click(refresh_button())
    |> assert_has(live_sessions(count: 2))
  end

  @sessions 2
  feature "settings button exists and redirects to settings page", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(css("navbar a[href=\"/settings\"]"))
    |> click(css("navbar a[href=\"/settings\"]"))
    |> assert_has(css("h1", text: "Settings"))
  end

  defp title(text: text), do: css("h1", text: text)

  defp live_sessions(count: count), do: css("#live-sessions > div", count: count)

  defp refresh_button(), do: css("button[phx-click=\"refresh\"]")
end
