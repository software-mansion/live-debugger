defmodule LiveDebugger.E2E.AssignsTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can search assigns using the searchbar", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(assigns_entry(key: "counter", value: "0"))
    |> fill_in(assigns_search_bar(), with: "deep value")
    |> assert_has(css("pre", text: "\"deep value\"", count: 1, visible: true))

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(assigns_entry(key: "counter", value: "0"))
    |> assert_has(fullscreen_button())
    |> click(fullscreen_button())
    |> fill_in(assigns_search_bar_fullscreen(), with: "deep value")
    |> assert_has(css("pre", text: "\"deep value\"", count: 2, visible: true))
  end

  @sessions 2
  feature "user can pin and unpin specific assigns", %{sessions: [dev_app, debugger]} do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(css("#pinned-assigns", text: "You have no pinned assigns."))
    |> hover(assigns_entry(key: "counter", value: "0"))

    Process.sleep(100)

    debugger
    |> click(pin_button("counter"))
    |> assert_has(pinned_assigns_entry(key: "counter", value: "0"))
    |> hover(assigns_entry(key: "datetime", value: "nil"))

    Process.sleep(100)

    debugger
    |> click(pin_button("datetime"))
    |> assert_has(pinned_assigns_entry(key: "datetime", value: "nil"))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))
    |> click(button("send-button"))

    debugger
    |> assert_has(assigns_entry(key: "counter", value: "2"))
    |> assert_has(assigns_entry(key: "datetime", value: "~U["))
    |> assert_has(pinned_assigns_entry(key: "counter", value: "2"))
    |> assert_has(pinned_assigns_entry(key: "datetime", value: "~U["))

    debugger
    |> hover(pinned_assigns_entry(key: "counter", value: "2"))
    |> click(unpin_button("counter"))
    |> hover(pinned_assigns_entry(key: "datetime", value: "~U["))
    |> click(unpin_button("datetime"))
    |> assert_has(css("#pinned-assigns", text: "You have no pinned assigns."))
  end

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"all-assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp pinned_assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"pinned-assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp fullscreen_button(), do: css("button[aria-label=\"Icon expand\"]")

  defp pin_button(assign_key, opts \\ []) do
    css("button[phx-click=\"pin-assign\"][phx-value-key=\"#{assign_key}\"]", opts)
  end

  defp unpin_button(assign_key, opts \\ []) do
    css("button[phx-click=\"unpin-assign\"][phx-value-key=\"#{assign_key}\"]", opts)
  end
end
