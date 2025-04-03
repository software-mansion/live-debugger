defmodule LiveDebugger.ChannelDashboardTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  @dev_app_url LiveDebuggerDev.Endpoint.url()

  setup :unset_mocks

  @sessions 2
  feature "user can visit Channel Dashboard", %{sessions: [dev_session, lvdbg_session]} do
    dev_session
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> click(css("#live-view-sessions a", count: 1))
    |> find(css("#module-name"))
    |> assert_has(css("div:first-child", text: "Module"))
    |> assert_has(css("div:last-child", text: "LiveDebuggerDev.LiveViews.Main"))
  end

  @sessions 2
  feature "user can see traces of executed callbacks", %{sessions: [dev_session, lvdbg_session]} do
    dev_session
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> click(css("#live-view-sessions a", count: 1))
    |> click(button("toggle-tracing"))

    dev_session
    |> click(button("increment"))

    lvdbg_session
    |> assert_has(css("#traces-list-stream details", count: 2))
  end

  @sessions 2
  feature "user can see updated assigns", %{sessions: [dev_session, lvdbg_session]} do
    dev_session
    |> visit(@dev_app_url)

    counter_element =
      lvdbg_session
      |> visit("/")
      |> click(css("#live-view-sessions a", count: 1))
      |> find(css("#assigns ol li:nth-child(2)"))
      |> assert_has(css("span:nth-child(3)", text: "0"))

    dev_session
    |> click(button("increment"))
    |> click(button("increment"))

    counter_element
    |> assert_has(css("span:nth-child(3)", text: "2"))
  end
end
