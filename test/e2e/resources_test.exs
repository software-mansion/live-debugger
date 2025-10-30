defmodule LiveDebugger.E2E.ResourcesTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can view process information in resources tab", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(resources_tab())
    |> assert_has(css("div#process-info"))
    |> assert_has(process_info_field("Initial Call"))
    |> assert_has(process_info_field("Current Function"))
    |> assert_has(process_info_field("Registered Name"))
    |> assert_has(process_info_field("Status"))
    |> assert_has(process_info_field("Message Queue Length"))
    |> assert_has(process_info_field("Priority"))
    |> assert_has(process_info_field("Reductions"))
    |> assert_has(process_info_field("Memory"))
    |> assert_has(process_info_field("Total Heap Size"))
    |> assert_has(process_info_field("Stack Size"))
    |> assert_has(refresh_select_button("Refresh Rate (5 s)"))
    |> click(refresh_select_button())
    |> assert_has(refresh_radio_button(1000, false))
    |> assert_has(refresh_radio_button(5000, true))
    |> assert_has(refresh_radio_button(15000, false))
    |> assert_has(refresh_radio_button(30000, false))
    |> click(refresh_radio_button(1000))
    |> assert_has(refresh_select_button("Refresh Rate (1 s)"))
    |> click(refresh_select_button())
    |> assert_has(refresh_radio_button(1000, true))
    |> assert_has(refresh_radio_button(5000, false))
    |> assert_has(refresh_radio_button(15000, false))
  end

  defp resources_tab() do
    css("a[href*='resources']", count: 1)
  end

  defp process_info_field(label) do
    css("span.font-medium", text: label)
  end

  defp refresh_select_button(text \\ "Refresh Rate") do
    css("button[aria-label='Refresh Rate']", text: text)
  end

  defp refresh_radio_button(value, checked) do
    css("input[type='radio'][value='#{value}']", checked: checked)
  end

  defp refresh_radio_button(value) do
    css("input[type='radio'][value='#{value}']")
  end
end
