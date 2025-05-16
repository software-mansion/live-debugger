defmodule LiveDebugger.WindowDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 3
  feature "user can see only active live views in the given window", %{
    sessions: [dev_app1, dev_app2, debugger]
  } do
    dev_app1
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))

    debugger
    |> click(window_link())
    |> assert_has(title(text: "Active LiveViews in single window"))
    |> assert_has(live_sessions(count: 1))

    dev_app2
    |> visit(@dev_app_url)

    debugger
    |> click(refresh_button())
    |> assert_has(live_sessions(count: 1))

    debugger
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))
  end

  defp title(text: text), do: css("h1", text: text)

  defp live_sessions(count: count), do: css("#live-sessions ", count: count)

  defp window_link(), do: css("#live-sessions a.window-link", count: 1)

  defp refresh_button(), do: css("button[phx-click=\"refresh\"]")
end
