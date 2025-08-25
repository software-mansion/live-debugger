defmodule LiveDebugger.E2E.ElementsInspectionTest do
  @moduledoc false

  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can inspect elements after enabling inspect mode from LiveDebugger", %{
    sessions: [dev_app1, debugger]
  } do
    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

    dev_app1
    |> assert_has(css("div.live-debugger-inspect-mode"))
    |> click(css("div[data-phx-component=\"2\"]"))
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
    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

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
    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

    dev_app1
    |> assert_has(css("div.live-debugger-inspect-mode"))
    |> click(:right)
    |> refute_has(css("div.live-debugger-inspect-mode"))
  end

  @sessions 4
  feature "selecting node redirects all debugger windows that are subscribed to it", %{
    sessions: [dev_app1, debugger1, debugger2, debugger3]
  } do
    dev_app1
    |> visit(@dev_app_url)
    |> refute_has(css("div.live-debugger-inspect-mode"))

    debugger1
    |> visit("/")
    |> click(first_link())
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

    debugger2
    |> visit("/")
    |> click(first_link())
    |> click(css("button[phx-click=\"switch-inspect-mode\"]"))

    debugger3
    |> visit("/")
    |> click(first_link())

    dev_app1
    |> click(css("div[data-phx-component=\"2\"]"))

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
end
