defmodule LiveDebugger.E2E.ResourcesTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp resources_tab(page), do: Page.locator(page, "a[href*='resources']") |> Locator.first()
  defp process_info_container(page), do: Page.locator(page, "div#process-info")

  defp process_info_field(page, label),
    do: Page.locator(page, "span.font-medium", has_text: label)

  defp refresh_select_btn(page), do: Page.locator(page, "button[aria-label='Refresh Rate']")

  defp refresh_radio_btn(page, value),
    do: Page.locator(page, "input[type='radio'][value='#{value}']")

  test "user can view process information in resources tab", %{dbg_app: dbg_app} do
    Locator.click!(resources_tab(dbg_app))
    Expect.to_be_visible!(process_info_container(dbg_app))

    expected_fields = [
      "Initial Call",
      "Current Function",
      "Registered Name",
      "Status",
      "Message Queue Length",
      "Priority",
      "Reductions",
      "Memory",
      "Total Heap Size",
      "Stack Size"
    ]

    for field <- expected_fields do
      Expect.to_be_visible!(process_info_field(dbg_app, field))
    end

    Expect.to_contain_text!(refresh_select_btn(dbg_app), "Refresh Rate (5 s)")

    Locator.click!(refresh_select_btn(dbg_app))

    Expect.not_to_be_checked!(refresh_radio_btn(dbg_app, 1000))
    Expect.to_be_checked!(refresh_radio_btn(dbg_app, 5000))
    Expect.not_to_be_checked!(refresh_radio_btn(dbg_app, 15_000))
    Expect.not_to_be_checked!(refresh_radio_btn(dbg_app, 30_000))

    Locator.click!(refresh_radio_btn(dbg_app, 1000))

    Expect.to_contain_text!(refresh_select_btn(dbg_app), "Refresh Rate (1 s)")

    Locator.click!(refresh_select_btn(dbg_app))

    Expect.to_be_checked!(refresh_radio_btn(dbg_app, 1000))
    Expect.not_to_be_checked!(refresh_radio_btn(dbg_app, 5000))
    Expect.not_to_be_checked!(refresh_radio_btn(dbg_app, 15_000))
  end
end
