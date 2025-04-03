defmodule LiveDebugger.LiveViewsDashboardTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  @dev_app_url LiveDebuggerDev.Endpoint.url()

  setup :unset_mocks

  feature "user can visit Active LiveViews page", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css("h1", text: "Active LiveViews"))
  end

  feature "user can see there is no active live views", %{session: session} do
    session
    |> visit("/")
    |> assert_has(css("#live-view-sessions > div > p", text: "No active LiveViews"))
  end

  @sessions 3
  feature "user can see multiple active live views", %{
    sessions: [dev_session1, dev_session2, lvdbg_session]
  } do
    dev_session1
    |> visit(@dev_app_url)

    dev_session2
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> assert_has(css("#live-view-sessions > div", count: 2))
  end

  @sessions 3
  feature "user can refresh to see more active live views", %{
    sessions: [dev_session1, dev_session2, lvdbg_session]
  } do
    dev_session1
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> assert_has(css("#live-view-sessions > div", count: 1))

    dev_session2
    |> visit(@dev_app_url)

    lvdbg_session
    |> assert_has(css("#live-view-sessions > div", count: 1))
    |> click(button("refresh"))
    |> assert_has(css("#live-view-sessions > div", count: 2))
  end
end
