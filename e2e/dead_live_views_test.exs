defmodule LiveDebugger.E2E.DeadLiveViewsTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp dead_sessions_container(page), do: Page.locator(page, "#dead-sessions")

  defp toggle_dead_live_views_btn(page),
    do: Page.locator(page, ~s|div[phx-click="toggle-dead-liveviews"]|)

  defp navbar_connected(page), do: Page.locator(page, "#navbar-connected")

  test "dead LiveViews are available to debug", %{dev_app: dev_app, dbg_app: dbg_app} do
    pid = get_dev_pid(dev_app)

    Locator.click!(return_button(dbg_app))

    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Active LiveViews"))

    if Locator.is_visible!(dead_sessions_container(dbg_app)) do
      Locator.click!(toggle_dead_live_views_btn(dbg_app))
    end

    Expect.not_to_be_visible!(dead_sessions_container(dbg_app))

    Locator.click!(toggle_dead_live_views_btn(dbg_app))
    Expect.to_be_visible!(dead_sessions_container(dbg_app))

    Page.goto!(dev_app, "/side")
    Page.goto!(dev_app, "/")

    dead_pid_btn =
      Page.locator(dbg_app, ~s|#dead-sessions button[id="#{pid}"][phx-click="select-live-view"]|)

    Expect.to_be_visible!(dead_pid_btn)
    Locator.hover!(dead_pid_btn)
    Locator.click!(dead_pid_btn)

    Expect.to_be_visible!(navbar_connected(dbg_app))
    Expect.to_contain_text!(navbar_connected(dbg_app), "Disconnected")
  end
end
