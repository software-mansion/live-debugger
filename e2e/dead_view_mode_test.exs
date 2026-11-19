defmodule LiveDebugger.E2E.DeadViewModeTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp navbar_connected(page), do: Page.locator(page, "#navbar-connected")
  defp components_tree(page), do: Page.locator(page, "#components-tree")
  defp crash_component_btn(page), do: Page.get_by_role(page, :button, name: "Crash (3)")
  defp global_traces_details(page), do: Page.locator(page, "#global-traces-stream > details")

  defp global_traces_with_error(page),
    do: Page.locator(page, "#global-traces-stream > details.border-error-border")

  defp dev_crash_btn(page), do: Page.locator(page, ~s|button[phx-click="crash"]|)

  describe "LiveDebugger Dead View Mode" do
    test "dead view mode with navigation", %{dev_app: dev_app, dbg_app: dbg_app} do
      Expect.to_contain_text!(navbar_connected(dbg_app), "Monitored PID")

      Page.reload!(dev_app)
      Expect.to_contain_text!(navbar_connected(dbg_app), "Disconnected")

      Expect.to_be_visible!(components_tree(dbg_app))
      Locator.click!(crash_component_btn(dbg_app))

      Expect.to_contain_text!(
        find_sidebar_basic_info(dbg_app),
        "LiveDebuggerDev.LiveComponents.Crash"
      )

      Locator.click!(find_global_traces_navbar_item(dbg_app))
      Expect.to_have_count!(global_traces_details(dbg_app), 25)
    end

    test "traces ended with exception are visible in dead view mode", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_global_traces_navbar_item(dbg_app))

      restart_tracing(dbg_app)

      Locator.click!(dev_crash_btn(dev_app))

      Expect.to_have_count!(global_traces_with_error(dbg_app), 1)
    end
  end
end
