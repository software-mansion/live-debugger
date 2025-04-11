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
    |> click(button("refresh"))
    |> assert_has(live_sessions(count: 2))
  end

  defp title(text: text),
    do: css("h1", text: text)

  defp live_sessions(count: count),
    do: css("#live-sessions > div", count: count)
end
