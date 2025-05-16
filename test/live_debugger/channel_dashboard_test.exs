defmodule LiveDebugger.ChannelDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can see traces of executed callbacks and updated assigns", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(assigns_entry(key: "counter", value: "0"))
    |> assert_has(traces(count: 2))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 2))
    |> assert_has(assigns_entry(key: "counter", value: "2"))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 6))
    |> assert_has(assigns_entry(key: "counter", value: "4"))
    |> click(toggle_tracing_button())
    |> click(clear_traces_button())
    |> assert_has(traces(count: 0))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 0))
    |> click(refresh_button())
    |> assert_has(traces(count: 4))
    |> click(clear_traces_button())

    dev_app
    |> click(button("slow-increment-button"))

    debugger
    |> click(refresh_button())
    |> assert_has(traces(count: 0))

    Process.sleep(405)

    assert debugger
           |> click(refresh_button())
           |> find(traces(count: 2))
           |> List.last()
           |> find(css("span.text-warning-text"))
           |> Element.text()
           |> String.match?(~r"^40\d ms$")

    debugger
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("very-slow-increment-button"))

    Process.sleep(2505)

    debugger
    |> find(traces(count: 4))
    |> Enum.at(1)
    |> assert_has(css("span.text-error-text", text: "2.50 s"))
  end

  @sessions 2
  feature "user can change nodes using node tree and see their assigns and callback traces", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(conditional_component_5_node_button())
    |> find(css("#info"), fn info ->
      info
      |> assert_text("LiveComponent")
      |> assert_text("LiveDebuggerDev.LiveComponents.Conditional")
    end)
    |> assert_has(assigns_entry(key: "show_child?", value: "false"))
    |> assert_has(traces(count: 2))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("conditional-button"))

    debugger
    |> assert_has(assigns_entry(key: "show_child?", value: "true"))
    |> assert_has(traces(count: 4))
    |> click(conditional_component_6_node_button())
    |> click(conditional_component_5_node_button())
    |> assert_has(assigns_entry(key: "show_child?", value: "true"))
    |> assert_has(traces(count: 4))
  end

  @sessions 2
  feature "user can filter callback traces", %{sessions: [dev_app, debugger]} do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(traces(count: 2))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("send-button"))
    |> click(button("send-button"))

    debugger
    |> assert_traces(6, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_info/2",
      "render/1",
      "mount/3"
    ])
    |> click(toggle_tracing_button())
    |> click(filters_button())
    |> click(checkbox("mount"))
    |> click(checkbox("render"))
    |> click(css("button", text: "Apply (7)"))
    |> assert_traces(2, [
      "handle_info/2",
      "handle_info/2"
    ])

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> click(refresh_button())
    |> assert_traces(4, [
      "handle_event/3",
      "handle_event/3",
      "handle_info/2",
      "handle_info/2"
    ])
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("send-button"))
    |> click(button("send-button"))

    debugger
    |> assert_traces(6, [
      "handle_info/2",
      "handle_info/2",
      "handle_event/3",
      "handle_event/3",
      "handle_info/2",
      "handle_info/2"
    ])
    |> click(toggle_tracing_button())
    |> click(filters_button())
    |> click(reset_filters_button())
    |> click(css("button", text: "Apply (9)"))
    |> assert_traces(14, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_info/2",
      "render/1",
      "mount/3"
    ])
  end

  defp assert_traces(session, count, callback_names) do
    session
    |> find(traces(count: count))
    |> Enum.zip(callback_names)
    |> Enum.each(fn {trace, callback_name} ->
      trace |> assert_text(callback_name)
    end)

    session
  end

  defp first_link(), do: css("#live-sessions a", count: 1)

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)

  defp toggle_tracing_button(), do: css("button[phx-click=\"switch-tracing\"]")

  defp refresh_button(), do: css("button[phx-click=\"refresh-history\"]")

  defp clear_traces_button(), do: css("button[phx-click=\"clear-traces\"]")

  defp filters_button(), do: css("button[phx-click=\"open\"]")

  defp reset_filters_button(), do: css("button[phx-click=\"reset\"]")

  defp conditional_component_5_node_button(),
    do: css("#tree-node-button-5-component-tree-sidebar-content")

  defp conditional_component_6_node_button(),
    do: css("#tree-node-button-6-component-tree-sidebar-content")
end
