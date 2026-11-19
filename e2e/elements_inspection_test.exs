defmodule LiveDebugger.E2E.ElementsInspectionTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"

  @dbg_url "http://localhost:4008"

  defp switch_inspect_mode_btn(page),
    do: Page.locator(page, ~s|button[phx-click="switch-inspect-mode"]|)

  defp live_component(page, cid), do: Page.locator(page, ~s|div[data-phx-component="#{cid}"]|)
  defp inspect_mode_overlay(page), do: Page.locator(page, "div.live-debugger-inspect-mode")

  defp inspect_tooltip_module(page),
    do: Page.locator(page, "div#live-debugger-tooltip div.live-debugger-tooltip-module")

  defp inspect_tooltip_type(page),
    do: Page.locator(page, "div#live-debugger-tooltip span.type-text")

  defp inspect_tooltip_value(page),
    do: Page.locator(page, "div#live-debugger-tooltip .id-info .value")

  defp sidebar_container(page), do: Page.locator(page, "#components-tree-sidebar-container")
  defp close_sidebar_btn(page), do: Page.locator(page, ~s|button[phx-click="close-sidebar"]|)

  defp select_live_view_by_pid(dbg_app, pid) do
    btn = Page.locator(dbg_app, ~s|button[id="#{pid}"][phx-click="select-live-view"]|)
    Locator.hover!(btn)
    Locator.click!(btn)
    Expect.to_be_visible!(find_sidebar_basic_info(dbg_app))
  end

  defp open_dbg_for_live_view(context, pid) do
    dbg_app = BrowserContext.new_page!(context)
    Page.goto!(dbg_app, @dbg_url)
    select_live_view_by_pid(dbg_app, pid)
    dbg_app
  end

  defp open_mobile_dbg_for_live_view(context, pid) do
    dbg_app = BrowserContext.new_page!(context)
    Page.set_viewport_size!(dbg_app, %{width: 600, height: 1000})
    Page.goto!(dbg_app, @dbg_url)
    btn = Page.locator(dbg_app, ~s|button[id="#{pid}"][phx-click="select-live-view"]|)
    Locator.hover!(btn)
    Locator.click!(btn)
    Expect.to_be_visible!(find_sidebar_basic_info(dbg_app))
    dbg_app
  end

  test "user can inspect elements after enabling inspect mode", %{
    dev_app: dev_app,
    context: context
  } do
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))

    pid = get_dev_pid(dev_app)
    dbg_app = open_dbg_for_live_view(context, pid)

    Locator.click!(switch_inspect_mode_btn(dbg_app))

    Expect.to_be_visible!(inspect_mode_overlay(dev_app))

    Locator.hover!(live_component(dev_app, 2))

    Expect.to_contain_text!(
      inspect_tooltip_module(dev_app),
      "LiveDebuggerDev.LiveComponents.Name"
    )

    Expect.to_contain_text!(inspect_tooltip_type(dev_app), "LiveComponent")
    Expect.to_contain_text!(inspect_tooltip_value(dev_app), "2")

    Locator.click!(live_component(dev_app, 2))

    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))
    Expect.to_contain_text!(find_node_module_info(dbg_app), "LiveDebuggerDev.LiveComponents.Name")
  end

  test "user can disable inspect mode from debugger", %{dev_app: dev_app, context: context} do
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))

    pid = get_dev_pid(dev_app)
    dbg_app = open_dbg_for_live_view(context, pid)

    Locator.click!(switch_inspect_mode_btn(dbg_app))
    Expect.to_be_visible!(inspect_mode_overlay(dev_app))

    Locator.click!(switch_inspect_mode_btn(dbg_app))
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))
  end

  test "user can disable inspect mode by right clicking", %{dev_app: dev_app, context: context} do
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))

    pid = get_dev_pid(dev_app)
    dbg_app = open_dbg_for_live_view(context, pid)

    Locator.click!(switch_inspect_mode_btn(dbg_app))
    Expect.to_be_visible!(inspect_mode_overlay(dev_app))

    Page.locator(dev_app, "body") |> Locator.click!(button: :right)
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))
  end

  test "selecting node redirects all subscribed debugger windows", %{
    dev_app: dev_app,
    context: context
  } do
    pid = get_dev_pid(dev_app)

    dbg_app1 = open_dbg_for_live_view(context, pid)
    Locator.click!(switch_inspect_mode_btn(dbg_app1))

    dbg_app2 = open_dbg_for_live_view(context, pid)
    Locator.click!(switch_inspect_mode_btn(dbg_app2))

    dbg_app3 = open_dbg_for_live_view(context, pid)

    Locator.click!(live_component(dev_app, 2))

    Expect.to_contain_text!(
      find_node_module_info(dbg_app1),
      "LiveDebuggerDev.LiveComponents.Name"
    )

    Expect.to_contain_text!(
      find_node_module_info(dbg_app2),
      "LiveDebuggerDev.LiveComponents.Name"
    )

    Expect.to_contain_text!(find_node_module_info(dbg_app3), "LiveDebuggerDev.LiveViews.Main")
  end

  @tag dev_url: "/embedded"
  @tag :dbg_app
  test "inspection works for nested LiveViews in LiveComponents", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))

    Locator.click!(switch_inspect_mode_btn(dbg_app))

    Page.locator(dev_app, ~s|div[data-phx-id*="embedded_wrapper_inner"] span|,
      has_text: "Simple [LiveView]"
    )
    |> Locator.click!()

    Expect.not_to_be_visible!(inspect_mode_overlay(dev_app))
    Expect.to_contain_text!(find_node_module_info(dbg_app), "LiveDebuggerDev.LiveViews.Simple")
  end

  test "sidebar opens automatically on small screens", %{dev_app: dev_app, context: context} do
    pid = get_dev_pid(dev_app)
    dbg_app = open_mobile_dbg_for_live_view(context, pid)

    Expect.not_to_be_visible!(sidebar_container(dbg_app))
    Expect.not_to_be_visible!(close_sidebar_btn(dbg_app))

    Locator.click!(switch_inspect_mode_btn(dbg_app))
    Locator.click!(live_component(dev_app, 2))

    Expect.to_be_visible!(sidebar_container(dbg_app))
    Expect.to_be_visible!(close_sidebar_btn(dbg_app))
  end

  test "sidebar closes on desktop resize and stays closed", %{
    dev_app: dev_app,
    context: context
  } do
    pid = get_dev_pid(dev_app)
    dbg_app = open_mobile_dbg_for_live_view(context, pid)

    Expect.not_to_be_visible!(sidebar_container(dbg_app))

    Locator.click!(switch_inspect_mode_btn(dbg_app))
    Locator.click!(live_component(dev_app, 2))

    Expect.to_be_visible!(sidebar_container(dbg_app))
    Expect.to_be_visible!(close_sidebar_btn(dbg_app))

    Page.set_viewport_size!(dbg_app, %{width: 1200, height: 1000})
    Page.set_viewport_size!(dbg_app, %{width: 600, height: 1000})

    Expect.not_to_be_visible!(sidebar_container(dbg_app))
    Expect.not_to_be_visible!(close_sidebar_btn(dbg_app))
  end
end
