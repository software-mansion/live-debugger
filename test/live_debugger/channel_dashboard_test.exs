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

    execution_time =
      debugger
      |> click(refresh_button())
      |> find(traces(count: 2))
      |> List.last()
      |> find(css("span.text-warning-text"))
      |> Element.text()

    assert execution_time =~ ~r"^40\d ms$"

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
    |> find(css("#info"))
    |> assert_text("LiveComponent")
    |> assert_text("LiveDebuggerDev.LiveComponents.Conditional")

    debugger
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

  defp first_link(), do: css("#live-sessions a", count: 1)

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)

  defp refresh_button(), do: css("button[phx-click=\"refresh-history\"]")

  defp toggle_tracing_button(), do: css("button[phx-click=\"switch-tracing\"]")

  defp clear_traces_button(), do: css("button[phx-click=\"clear-traces\"]")

  defp conditional_component_5_node_button(),
    do: css("#tree-node-button-5-component-tree-sidebar-content")

  defp conditional_component_6_node_button(),
    do: css("#tree-node-button-6-component-tree-sidebar-content")
end
