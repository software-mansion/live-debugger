defmodule LiveDebugger.E2E.AssignsTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "user can search assigns using the searchbar", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(term_entry("all-assigns", key: "counter", value: "0"))
    |> fill_in(assigns_search_bar(), with: "deep value")
    |> assert_has(css("pre", text: "\"deep value\"", count: 1, visible: true))

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(term_entry("all-assigns", key: "counter", value: "0"))
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
    |> select_live_view()
    |> assert_has(css("#pinned-assigns", text: "You have no pinned assigns."))

    debugger
    |> click_pin_button("counter")
    |> assert_has(term_entry("pinned-assigns", key: "counter", value: "0"))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))
    |> click(button("send-button"))

    debugger
    |> assert_has(term_entry("all-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("pinned-assigns", key: "counter", value: "2"))

    debugger
    |> click_unpin_button("counter")
    |> assert_has(css("#pinned-assigns", text: "You have no pinned assigns."))
  end

  @sessions 2
  feature "user can go through assigns change history", %{sessions: [dev_app, debugger]} do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()

    dev_app
    |> visit(@dev_app_url)
    |> click(button("increment-button"))
    |> click(button("increment-button"))
    |> click(button("send-button"))

    debugger
    |> visit("/")
    |> select_live_view()
    |> click(open_assigns_history_button())
    |> assert_has(term_entry("history-old-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-old-assigns", key: "datetime", value: "nil"))
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-new-assigns", key: "datetime", value: "~U["))
    |> click(go_back_history_button())
    |> assert_has(term_entry("history-old-assigns", key: "counter", value: "1"))
    |> assert_has(term_entry("history-old-assigns", key: "datetime", value: "nil"))
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-new-assigns", key: "datetime", value: "nil"))
    |> click(go_forward_history_button())
    |> assert_has(term_entry("history-old-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-old-assigns", key: "datetime", value: "nil"))
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-new-assigns", key: "datetime", value: "~U["))
    |> click(go_all_back_history_button())
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "0"))
    |> assert_has(term_entry("history-new-assigns", key: "datetime", value: "nil"))
    |> click(go_all_forward_history_button())
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "2"))
    |> assert_has(term_entry("history-new-assigns", key: "datetime", value: "~U["))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(term_entry("history-old-assigns", key: "counter", value: "3"))
    |> assert_has(term_entry("history-new-assigns", key: "counter", value: "4"))
    |> click(button("assigns-history-close"))
    |> click(clear_traces_button())
    |> click(open_assigns_history_button())
    |> assert_has(css("#assigns-history", text: "No history records"))
  end

  defp term_entry(container_id, key: key, value: value) do
    xpath(
      ".//*[@id=\"#{container_id}\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp fullscreen_button(), do: css("button[aria-label=\"Icon expand\"]")

  defp open_assigns_history_button(), do: css("button[phx-click=\"open-assigns-history\"]")

  defp go_back_history_button(), do: css("button[phx-click=\"go-back\"]")

  defp go_forward_history_button(), do: css("button[phx-click=\"go-forward\"]")

  defp go_all_back_history_button(), do: css("button[phx-click=\"go-back-end\"]")

  defp go_all_forward_history_button(), do: css("button[phx-click=\"go-forward-end\"]")

  defp click_pin_button(debugger, assign_key) do
    selector = "button[phx-click=\"pin-assign\"][phx-value-key=\"#{assign_key}\"]"

    debugger
    |> show_button(selector)
    |> click(css(selector))
  end

  defp click_unpin_button(debugger, assign_key) do
    selector = "button[phx-click=\"unpin-assign\"][phx-value-key=\"#{assign_key}\"]"

    debugger
    |> show_button(selector)
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
