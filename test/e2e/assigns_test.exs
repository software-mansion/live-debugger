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

    debugger
    |> click_pin_button("counter")
    |> assert_has(pinned_assigns_entry(key: "counter", value: "0"))

    debugger
    |> click_pin_button("datetime")
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
    |> click_unpin_button("counter")
    |> click_unpin_button("datetime")
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

  defp click_pin_button(debugger, assign_key) do
    selector = "button[phx-click=\"pin-assign\"][phx-value-key=\"#{assign_key}\"]"

    debugger
    |> show_button(selector)

    # Adding small sleep to ensure the button is visible
    Process.sleep(100)

    debugger
    |> click(css(selector))
  end

  defp click_unpin_button(debugger, assign_key) do
    selector = "button[phx-click=\"unpin-assign\"][phx-value-key=\"#{assign_key}\"]"

    debugger
    |> show_button(selector)

    # Adding small sleep to ensure the button is visible
    Process.sleep(100)

    debugger
    |> click(css(selector))
  end

  # Apparently hover does not work on our CI and since testing hover is not a priority for now, we decided to bypass it.
  defp show_button(debugger, selector) do
    debugger
    |> execute_script(
      """
        var el = document.querySelector(arguments[0]);
        if (el) { el.style.display = 'block'; }
      """,
      [selector]
    )
  end
end
