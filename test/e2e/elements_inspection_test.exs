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
    |> take_screenshot()
    |> assert_has(
      css("#node-inspector-basic-info-current-node-module",
        text: "LiveDebuggerDev.LiveComponents.Name"
      )
    )
  end
end
