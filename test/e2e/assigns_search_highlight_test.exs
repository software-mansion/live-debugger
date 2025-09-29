defmodule LiveDebugger.E2E.AssignsSearchHighlightTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can search assigns using the searchbar", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    Process.sleep(200)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(assigns_entry(key: "counter", value: "0"))
    |> fill_in(assigns_search_bar(), with: "deep value")
    |> assert_has(css("pre", text: "\"deep value\"", count: 1, visible: true))

    Process.sleep(200)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(assigns_entry(key: "counter", value: "0"))
    |> assert_has(fullscreen_button())
    |> click(fullscreen_button())
    |> fill_in(assigns_search_bar_fullscreen(), with: "deep value")
    |> assert_has(css("pre", text: "\"deep value\"", count: 2, visible: true))
  end

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp fullscreen_button(), do: css("button[aria-label=\"Icon expand\"]")
end
