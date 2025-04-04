defmodule LiveDebugger.LiveViewsDashboardTest do
  use ExUnit.Case
  use Wallaby.Feature

  import Wallaby.Query

  @dev_app_url Application.compile_env(:live_debugger, :dev_app_url)

  @moduletag :e2e

  @sessions 3
  feature "user can see active live views and refresh to see more", %{
    sessions: [dev_session1, dev_session2, lvdbg_session]
  } do
    dev_session1
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))

    dev_session2
    |> visit(@dev_app_url)

    lvdbg_session
    |> assert_has(live_sessions(count: 1))
    |> click(button("refresh"))
    |> assert_has(live_sessions(count: 2))
  end

  defp title(text: text),
    do: css("h1", text: text)

  defp live_sessions(count: count),
    do: css("#live-sessions > div", count: count)
end
