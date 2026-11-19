defmodule LiveDebugger.E2E.AssociatedLiveViewsTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/embedded"
  @moduletag :dbg_app

  test "user can see all associated LiveViews to currently debugged LiveView", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Expect.to_have_text!(find_node_module_info(dbg_app), "LiveDebuggerDev.LiveViews.Embedded")

    Expect.to_have_count!(Page.locator(dbg_app, "#associated-live-views button"), 6)

    nested_live_view_node =
      Page.get_by_role(dbg_app, :button, name: "LiveDebuggerDev.LiveViews.Nested")
      |> Locator.first()

    Locator.hover!(nested_live_view_node)
    Locator.click!(nested_live_view_node)

    Expect.to_have_text!(find_node_module_info(dbg_app), "LiveDebuggerDev.LiveViews.Nested")

    show_toggle_button = Page.get_by_role(dev_app, :button, name: "Show") |> Locator.nth(3)

    Locator.click!(show_toggle_button)

    Expect.to_have_count!(Page.locator(dbg_app, "#associated-live-views button"), 7)

    Locator.click!(show_toggle_button)

    Expect.to_have_count!(Page.locator(dbg_app, "#associated-live-views button"), 6)
  end
end
