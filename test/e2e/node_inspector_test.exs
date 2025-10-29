defmodule LiveDebugger.E2E.NodeInspectorTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "user can see traces of executed callbacks and updated assigns", %{
    sessions: [dev_app, debugger]
  } do
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
    |> click(refresh_history_button())
    |> assert_has(traces(count: 4))
    |> click(clear_traces_button())

    # Callback traces have proper execution times displayed
    dev_app
    |> click(button("slow-increment-button"))

    debugger
    |> click(refresh_history_button())
    |> assert_has(traces(count: 0))

    Process.sleep(405)

    assert debugger
           |> click(refresh_history_button())
           |> find(traces(count: 2))
           |> List.last()
           |> find(css("span.text-warning-text"))
           |> Element.text()
           |> String.match?(~r"^40\d ms$")

    debugger
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("very-slow-increment-button"))

    Process.sleep(1105)

    debugger
    |> find(traces(count: 4))
    |> Enum.at(1)
    |> assert_has(css("span.text-error-text", text: "1.10 s"))
  end

  @sessions 2
  feature "settings button exists and redirects works as expected", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(css("div#traces", text: "Callback traces"))
    |> assert_has(settings_button())
    |> click(settings_button())
    |> assert_has(css("h1", text: "Settings"))
    |> assert_has(return_button())
    |> click(return_button())
    |> assert_has(css("div#traces", text: "Callback traces"))
  end

  @sessions 2
  feature "return button redirects to active live views dashboard", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(css("div#traces", text: "Callback traces"))
    |> click(return_button())
    |> assert_has(css("h1", text: "Active LiveViews"))
  end

  @sessions 2
  feature "user can change nodes using node tree and see their assigns and callback traces", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(conditional_component_5_node_button())
    |> find(sidebar_basic_info(), fn info ->
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
    |> assert_has(many_assigns_15_node_button())
    |> assert_has(assigns_entry(key: "show_child?", value: "true"))
    |> assert_has(traces(count: 4))
    |> click(conditional_component_6_node_button())
    |> click(conditional_component_5_node_button())
    |> assert_has(assigns_entry(key: "show_child?", value: "true"))
    |> assert_has(traces(count: 4))
  end

  @sessions 2
  feature "user can filter traces by callback name", %{sessions: [dev_app, debugger]} do
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
    |> click(css("button", text: "Apply"))
    |> assert_traces(2, [
      "handle_info/2",
      "handle_info/2"
    ])

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> click(refresh_history_button())
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
    |> click(reset_button())
    |> click(css("button", text: "Apply"))
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
    |> click(filters_button())
    |> click(checkbox("mount"))
    |> click(checkbox("handle_params"))
    |> click(checkbox("handle_info"))
    |> click(checkbox("handle_call"))
    |> click(checkbox("handle_cast"))
    |> click(checkbox("terminate"))
    |> click(checkbox("render"))
    |> click(checkbox("handle_event"))
    |> click(checkbox("handle_async"))
    |> click(css("button", text: "Apply"))
    |> assert_has(traces(count: 0))
  end

  @sessions 2
  feature "user can filter traces by execution time", %{sessions: [dev_app, debugger]} do
    dev_app
    |> visit(@dev_app_url)
    |> click(button("slow-increment-button"))

    Process.sleep(405)

    dev_app
    |> click(button("very-slow-increment-button"))

    Process.sleep(1105)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_traces(6, [
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3",
      "render/1",
      "mount/3"
    ])
    |> click(filters_button())
    |> set_value(select("min_unit"), "ms")
    |> fill_in(text_field("exec_time_min"), with: 100)
    |> set_value(select("max_unit"), "s")
    |> fill_in(text_field("exec_time_max"), with: 1)
    |> send_keys([:enter])
    |> find(traces(count: 1))
    |> find(css("span.text-warning-text"))
    |> Element.text()
    |> String.match?(~r"^40\d ms$")

    debugger
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("increment-button"))
    |> click(button("slow-increment-button"))

    Process.sleep(405)

    debugger
    |> find(traces(count: 2))
    |> Enum.each(fn trace ->
      find(trace, css("span.text-warning-text"))
      |> Element.text()
      |> String.match?(~r"^40\d ms$")
    end)
  end

  @sessions 2
  feature "user can filter traces by names and execution time", %{sessions: [dev_app, debugger]} do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(traces(count: 2))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("slow-increment-button"))
    |> click(button("increment-button"))
    |> click(button("send-button"))

    Process.sleep(405)

    debugger
    |> assert_traces(8, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3",
      "render/1",
      "mount/3"
    ])
    |> click(toggle_tracing_button())
    |> click(filters_button())
    |> set_value(select("min_unit"), "ms")
    |> fill_in(text_field("exec_time_min"), with: 100)
    |> click(checkbox("mount"))
    |> click(checkbox("render"))
    |> click(css("button", text: "Apply"))
    |> assert_traces(1, [
      "handle_event/3"
    ])

    dev_app
    |> click(button("slow-increment-button"))
    |> click(button("send-button"))

    Process.sleep(405)

    debugger
    |> click(refresh_history_button())
    |> assert_traces(2, [
      "handle_event/3",
      "handle_event/3"
    ])
    |> click(filters_button())
    |> click(reset_group_button("execution_time"))
    |> click(css("button", text: "Apply"))
    |> assert_traces(5, [
      "handle_info/2",
      "handle_event/3",
      "handle_info/2",
      "handle_event/3",
      "handle_event/3"
    ])
    |> click(filters_button())
    |> fill_in(text_field("exec_time_max"), with: 100)
    |> click(reset_group_button("functions"))
    |> click(css("button", text: "Apply"))
    |> assert_traces(10, [
      "render/1",
      "handle_info/2",
      "render/1",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "render/1",
      "mount/3"
    ])
    |> click(filters_button())
    |> click(checkbox("handle_info"))
    |> click(css("button", text: "Apply"))
    |> assert_traces(8, [
      "render/1",
      "render/1",
      "render/1",
      "render/1",
      "handle_event/3",
      "render/1",
      "render/1",
      "mount/3"
    ])
    |> click(reset_filters_button())
    |> assert_traces(12, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3",
      "render/1",
      "mount/3"
    ])
  end

  @sessions 2
  feature "user can inspect arguments of executed callback", %{sessions: [dev_app, debugger]} do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("increment-button"))
    |> click(button("send-button"))

    [render3_trace, send_trace, render2_trace, increment_trace, render1_trace, _] =
      debugger
      |> find(traces(count: 6))

    render1_trace
    |> click(css("summary"))
    |> assert_has(map_entry(key: "datetime", value: "nil"))
    |> assert_has(map_entry(key: "counter", value: "0"))

    increment_trace
    |> click(css("summary"))
    |> assert_text("handle_event/3")
    |> assert_text("increment")

    render2_trace
    |> click(css("summary"))
    |> assert_has(map_entry(key: "datetime", value: "nil"))
    |> assert_has(map_entry(key: "counter", value: "1"))

    send_trace
    |> click(css("summary"))
    |> assert_text("handle_info/2")
    |> assert_text(":new_datetime")

    render3_trace
    |> click(css("summary"))
    |> assert_has(map_entry(key: "datetime", value: "~U["))
    |> assert_has(map_entry(key: "counter", value: "1"))
  end

  @sessions 2
  feature "when user navigates in debugged app, it causes dead view mode", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> find(sidebar_basic_info())
    |> assert_text("LiveDebuggerDev.LiveViews.Main")

    dev_app
    |> click(link("Side"))

    Process.sleep(500)

    debugger
    |> find(css("#navbar-connected"))
    |> assert_text("Disconnected")

    debugger
    |> click(css("button", text: "Continue"))

    Process.sleep(1000)

    debugger
    |> find(sidebar_basic_info())
    |> assert_text("LiveDebuggerDev.LiveViews.Side")
  end

  @sessions 2
  feature "user can copy values", %{sessions: [dev_app, debugger]} do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_text("LiveDebuggerDev.LiveViews.Main")
    |> execute_script("""
      window._copiedText = null;

      navigator.clipboard.writeText = function(text) {
        window._copiedText = text;
        return Promise.resolve();
      };

      document.execCommand = function(cmd) {
        if (cmd === 'copy') {
          const selectedText = window.getSelection().toString();
          window._copiedText = selectedText;
          return true;
        }
        return false;
      };
    """)
    |> click(css("button#copy-button-module-name"))
    |> execute_script("return window._copiedText;", fn copied_text ->
      assert copied_text == "LiveDebuggerDev.LiveViews.Main"
    end)
  end

  @sessions 2
  feature "user can highlight nodes", %{sessions: [dev_app, debugger]} do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(highlight_switch())
    |> hover(name_component_2_node_button())

    Process.sleep(400)

    dev_app
    |> assert_has(inspect_tooltip_module_text("LiveDebuggerDev.LiveComponents.Name"))
    |> assert_has(inspect_tooltip_type_text("LiveComponent"))
    |> assert_has(inspect_tooltip_value_text("2"))
  end

  @sessions 2
  feature "user can search for callbacks using the searchbar", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(traces(count: 2))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("send-button"))

    debugger
    |> click(toggle_tracing_button())

    debugger
    |> fill_in(search_bar(), with: ":new_datetime")

    Process.sleep(250)

    debugger
    |> find(traces(count: 1), fn trace -> assert_text(trace, ":new_datetime") end)
    |> click(clear_traces_button())

    dev_app
    |> click(button("increment-button"))

    debugger
    |> fill_in(search_bar(), with: "deep value")

    Process.sleep(250)

    [render_trace, handle_event_trace] = debugger |> find(traces(count: 2))

    render_trace
    |> click(css("summary"))
    |> assert_has(css("pre", text: "\"deep value\"", count: 2, visible: true))
    |> click(open_fullscreen_trace_button())

    debugger
    |> find(css("#trace-fullscreen"))
    |> assert_has(css("pre", text: "\"deep value\"", count: 2, visible: true))
    |> click(button("trace-fullscreen-close"))

    handle_event_trace
    |> click(css("summary"))
    |> assert_has(css("pre", text: "\"deep value\"", count: 1, visible: true))
    |> click(open_fullscreen_trace_button())

    debugger
    |> find(css("#trace-fullscreen"))
    |> assert_has(css("pre", text: "\"deep value\"", count: 1, visible: true))
  end

  @sessions 2
  feature "incoming traces are filtered by search phrase", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(traces(count: 2))
    |> fill_in(search_bar(), with: ":new_datetime")

    Process.sleep(250)

    debugger
    |> assert_has(traces(count: 0))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("send-button"))

    debugger
    |> assert_has(traces(count: 1))
  end

  defp assert_traces(session, count, callback_names) do
    session
    |> find(traces(count: count))
    |> case do
      traces when is_list(traces) -> traces
      trace -> [trace]
    end
    |> Enum.zip(callback_names)
    |> Enum.each(fn {trace, callback_name} ->
      trace |> assert_text(callback_name)
    end)

    session
  end

  defp assigns_entry(key: key, value: value) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]"
    )
  end

  defp map_entry(key: key, value: value) do
    xpath(
      ".//*[contains(normalize-space(text()), \"#{key}:\")]/../..//*[contains(normalize-space(text()), \"#{value}\")]",
      count: :any
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)

  defp filters_button(), do: css("button[phx-click=\"open-filters\"]")

  defp reset_button(), do: css("button[phx-click=\"reset\"]")

  defp reset_filters_button(), do: css("button[phx-click=\"reset-filters\"]")

  defp name_component_2_node_button() do
    css("#button-tree-node-2-components-tree")
  end

  defp conditional_component_5_node_button() do
    css("#button-tree-node-5-components-tree")
  end

  defp conditional_component_6_node_button() do
    css("#button-tree-node-6-components-tree")
  end

  defp many_assigns_15_node_button() do
    css("#button-tree-node-15-components-tree")
  end

  defp reset_group_button(group) do
    css("button[phx-click=\"reset-group\"][phx-value-group=\"#{group}\"]")
  end

  defp open_fullscreen_trace_button(), do: css("button[phx-click=\"open-trace\"]")

  # The toggle_switch component uses a hidden checkbox input with class "sr-only" (screen reader only).
  # Wallaby cannot click on hidden elements, so we need to click on the visible label element
  # that contains the checkbox instead of the checkbox itself.
  defp highlight_switch() do
    xpath("//label[.//input[@id='highlight-switch']]")
  end
end
