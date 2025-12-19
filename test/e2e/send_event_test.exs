defmodule LiveDebugger.E2E.SendEventTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "user can send events to LiveView and LiveComponent, button disabled when dead", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    # Open debugger and select the LiveView
    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(sidebar_basic_info())
    |> assert_has(assigns_entry(key: "counter", value: "0"))

    # Send :increment message to LiveView via handle_info/2
    debugger
    |> click(send_event_button())

    Process.sleep(300)

    debugger
    |> assert_has(send_event_fullscreen_visible())
    |> set_value(handler_select(), "handle_info/2")
    |> fill_in(payload_textarea(), with: ":increment")
    |> click(send_button())

    Process.sleep(300)

    # Counter should be incremented
    debugger
    |> refute_has(send_event_fullscreen_visible())
    |> assert_has(assigns_entry(key: "counter", value: "1"))

    # Switch to Conditional LiveComponent
    debugger
    |> click(conditional_component_node_button())

    Process.sleep(300)

    debugger
    |> assert_has(assigns_entry(key: "show_child?", value: "false"))
    |> click(send_event_button())

    Process.sleep(300)

    debugger
    |> assert_has(send_event_fullscreen_visible())
    |> set_value(handler_select(), "handle_event/3")
    |> fill_in(event_input(), with: "show_child")
    |> click(send_button())

    Process.sleep(300)

    # show_child? should be true now
    debugger
    |> refute_has(send_event_fullscreen_visible())
    |> assert_has(assigns_entry(key: "show_child?", value: "true"))

    # Send assigns via update/2 to set show_child? back to false
    debugger
    |> click(send_event_button())

    Process.sleep(300)

    debugger
    |> assert_has(send_event_fullscreen_visible())
    |> set_value(handler_select(), "update/2")
    |> fill_in(payload_textarea(), with: "%{show_child?: false}")
    |> click(send_button())

    Process.sleep(300)

    # show_child? should be false again
    debugger
    |> refute_has(send_event_fullscreen_visible())
    |> assert_has(assigns_entry(key: "show_child?", value: "false"))

    # Navigate in dev app to kill the LiveView
    dev_app
    |> click(link("Side"))

    Process.sleep(500)

    # Debugger should show disconnected state
    debugger
    |> find(css("#navbar-connected"))
    |> assert_text("Disconnected")

    # Send Event button should be disabled when LiveView is dead
    debugger
    |> assert_has(send_event_button_disabled())
  end

  defp send_event_button(), do: css("button#send-event-button")
  defp send_event_button_disabled(), do: css("button#send-event-button[disabled]")
  defp send_event_fullscreen_visible(), do: css("dialog#send-event-fullscreen[open]")
  defp handler_select(), do: css("select#send-event-fullscreen-form_handler")
  defp event_input(), do: css("input#send-event-fullscreen-form_event")
  defp payload_textarea(), do: css("textarea#send-event-fullscreen-form_payload")
  defp send_button(), do: css("dialog#send-event-fullscreen button[type=\"submit\"]")

  defp conditional_component_node_button() do
    css("#button-tree-node-5-components-tree")
  end

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end
end
