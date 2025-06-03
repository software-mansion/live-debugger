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
  feature "settings button exists and redirects works as expected", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(settings_button())
    |> click(settings_button())
    |> assert_has(css("h1", text: "Settings"))
    |> assert_has(return_button())
    |> click(return_button())
    |> assert_has(title(text: "Active LiveViews"))
  end

  defp title(text: text), do: css("h1", text: text)

  defp live_sessions(count: count), do: css("#live-sessions > div", count: count)

  defp refresh_button(), do: css("button[phx-click=\"refresh\"]")

  defp settings_button(), do: css("navbar a#settings-button")

  defp return_button(), do: css("navbar a#return-button")
end
