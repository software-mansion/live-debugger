defmodule LiveDebugger.E2E.DiscoverySerialTest do
  # Runs after the parallel modules (ExUnit runs sync modules after async ones).
  use LiveDebugger.E2E.Case,
    async: false,
    parameterize: LiveDebugger.E2E.Case.projects("serial-tests")

  @dbg_url "http://localhost:4008"

  defp find_inspect_tooltip_module_text(page),
    do: Page.locator(page, "div#live-debugger-tooltip div.live-debugger-tooltip-module")

  defp find_inspect_tooltip_type_text(page),
    do: Page.locator(page, "div#live-debugger-tooltip span.type-text")

  test "user can see active live views and their highlights which are refreshed automatically", %{
    page: dev_app,
    context: context
  } do
    Page.goto!(dev_app, "/")

    dbg_app = BrowserContext.new_page!(context)
    Page.goto!(dbg_app, @dbg_url)

    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Active LiveViews"))

    dev_pid_string1 =
      Page.locator(dev_app, "#current-pid") |> Locator.text_content!() |> to_string()

    Expect.to_be_visible!(Page.get_by_text(dbg_app, dev_pid_string1))

    dev_app2 = BrowserContext.new_page!(context)
    Page.goto!(dev_app2, "/")

    dev_pid_string2 =
      Page.locator(dev_app2, "#current-pid") |> Locator.text_content!() |> to_string()

    Expect.to_be_visible!(Page.get_by_text(dbg_app, dev_pid_string2))

    Page.get_by_text(dbg_app, dev_pid_string1) |> Locator.hover!()

    Expect.to_contain_text!(
      find_inspect_tooltip_module_text(dev_app),
      "LiveDebuggerDev.LiveViews.Main"
    )

    Expect.to_contain_text!(find_inspect_tooltip_type_text(dev_app), "LiveView")

    Expect.not_to_be_visible!(find_inspect_tooltip_module_text(dev_app2))
    Expect.not_to_be_visible!(find_inspect_tooltip_type_text(dev_app2))

    Page.get_by_text(dbg_app, dev_pid_string2) |> Locator.hover!()

    Expect.to_contain_text!(
      find_inspect_tooltip_module_text(dev_app2),
      "LiveDebuggerDev.LiveViews.Main"
    )

    Expect.to_contain_text!(find_inspect_tooltip_type_text(dev_app2), "LiveView")

    Expect.not_to_be_visible!(find_inspect_tooltip_module_text(dev_app))
    Expect.not_to_be_visible!(find_inspect_tooltip_type_text(dev_app))
  end

  test "settings button exists and redirects works as expected", %{page: dbg_app} do
    Page.goto!(dbg_app, @dbg_url)

    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Active LiveViews"))

    Page.get_by_role(dbg_app, :link, name: "Icon settings") |> Locator.click!()

    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Settings"))

    Page.get_by_role(dbg_app, :link, name: "Icon arrow left") |> Locator.click!()

    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Active LiveViews"))
  end
end
