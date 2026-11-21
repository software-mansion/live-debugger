defmodule LiveDebugger.E2E.SettingsSerialTest do
  # Runs after the parallel modules (ExUnit runs sync modules after async ones).
  use LiveDebugger.E2E.Case,
    async: false,
    parameterize: LiveDebugger.E2E.Case.projects("serial-tests")

  defp dead_view_mode_input(page),
    do: Page.locator(page, ~s|input[phx-value-setting="dead_view_mode"]|)

  defp dead_view_mode_label(page),
    do: Page.locator(page, ~s|label:has(input[phx-value-setting="dead_view_mode"])|)

  defp document(page), do: Page.get_by_role(page, :document)

  describe "settings" do
    @describetag :settings

    test "dead view mode is togglable", %{page: dev_app, context: context} do
      Page.goto!(dev_app, "/")
      Page.locator(dev_app, "#live-debugger-debug-button") |> Locator.click!()

      dbg_app1 =
        Page.expect_popup!(dev_app, fn ->
          Page.get_by_text(dev_app, "Open in new tab") |> Locator.click!()
        end)

      dbg_app2 = BrowserContext.new_page!(context)
      Page.goto!(dbg_app2, "http://localhost:4008/settings")

      Expect.to_contain_text!(document(dbg_app1), "Monitored PID")
      Expect.to_contain_text!(document(dbg_app1), "LiveDebuggerDev.LiveViews.Main")

      Page.get_by_role(dev_app, :link, name: "Side") |> Locator.click!()

      Expect.to_contain_text!(document(dbg_app1), "Disconnected")
      Expect.to_contain_text!(document(dbg_app1), "LiveDebuggerDev.LiveViews.Main")

      Page.get_by_role(dbg_app1, :button, name: "Continue") |> Locator.click!()

      Expect.to_contain_text!(document(dbg_app1), "Monitored PID")
      Expect.to_contain_text!(document(dbg_app1), "LiveDebuggerDev.LiveViews.Side")

      Page.get_by_role(dbg_app1, :link, name: "Icon settings") |> Locator.click!()

      Expect.to_be_checked!(dead_view_mode_input(dbg_app1))
      Expect.to_be_checked!(dead_view_mode_input(dbg_app2))

      Locator.click!(dead_view_mode_label(dbg_app1))

      Expect.to_be_checked!(dead_view_mode_input(dbg_app1), checked: false)
      Expect.to_be_checked!(dead_view_mode_input(dbg_app2), checked: false)

      Page.get_by_role(dbg_app1, :link, name: "Icon arrow left") |> Locator.click!()

      Expect.to_contain_text!(document(dbg_app1), "Monitored PID")
      Expect.to_contain_text!(document(dbg_app1), "LiveDebuggerDev.LiveViews.Side")

      Page.get_by_role(dev_app, :link, name: "Main") |> Locator.click!()

      Expect.to_contain_text!(document(dbg_app1), "Monitored PID")
      Expect.to_contain_text!(document(dbg_app1), "LiveDebuggerDev.LiveViews.Main")

      Page.get_by_role(dbg_app1, :link, name: "Icon settings") |> Locator.click!()
      Locator.click!(dead_view_mode_label(dbg_app1))
    end
  end
end
