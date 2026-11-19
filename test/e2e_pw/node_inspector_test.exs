defmodule LiveDebugger.E2E.NodeInspectorTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  @filters_form "#filters-fullscreen-form"

  defp find_node_basic_info(page), do: Page.locator(page, "#node-inspector-basic-info")
  defp find_components_tree_button(page, name), do: Page.get_by_role(page, :button, name: name)

  defp find_callback_checkbox(page, name) do
    Page.locator(page, "#{@filters_form} div.flex.items-center", has_text: name)
    |> Locator.locator(~s|input[type="checkbox"]|)
  end

  defp find_exec_time_min_input(page), do: Page.locator(page, "#{@filters_form}_exec_time_min")
  defp find_exec_time_max_input(page), do: Page.locator(page, "#{@filters_form}_exec_time_max")
  defp find_min_unit_select(page), do: Page.locator(page, "#{@filters_form}_min_unit")
  defp find_max_unit_select(page), do: Page.locator(page, "#{@filters_form}_max_unit")
  defp find_apply_button(page), do: Page.locator(page, ~s|#{@filters_form} button[type="submit"]|)

  defp find_reset_all_button(page),
    do: Page.locator(page, ~s|#{@filters_form} button[phx-click="reset"]|)

  defp find_reset_group_button(page, group),
    do: Page.locator(page, ~s|button[phx-click="reset-group"][phx-value-group="#{group}"]|)

  defp find_reset_filters_button(page),
    do: Page.locator(page, ~s|button[phx-click="reset-filters"]|)

  defp find_search_bar(page), do: Page.locator(page, "#trace-search-input")

  defp find_open_fullscreen_trace_button(page),
    do: Page.locator(page, ~s|button[phx-click="open-trace"]|)

  # Tooltip (on devApp)
  defp find_inspect_tooltip_module_text(page),
    do: Page.locator(page, "div#live-debugger-tooltip div.live-debugger-tooltip-module")

  defp find_inspect_tooltip_type_text(page),
    do: Page.locator(page, "div#live-debugger-tooltip span.type-text")

  defp find_inspect_tooltip_value_text(page),
    do: Page.locator(page, "div#live-debugger-tooltip .id-info span.value")

  # Trace name assertions helper
  defp assert_trace_names(page, expected_names) do
    traces = find_traces(page)
    Expect.to_contain_text!(traces, expected_names)
    Expect.to_have_count!(traces, length(expected_names))
  end

  # Map entry in trace details (scoped to a trace element)
  defp find_map_entry(parent, key, value) do
    parent
    |> Locator.locator(
      ~s|xpath=.//*[contains(normalize-space(text()), "#{key}:")]/../..//*[contains(normalize-space(text()), "#{value}")]|
    )
    |> Locator.first()
  end

  test "user can see traces of executed callbacks and updated assigns", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    traces = find_traces(dbg_app)
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "counter", "0"))
    Expect.to_have_count!(traces, 2)

    inc_btn = Page.get_by_role(dev_app, :button, name: "Increment", exact: true)
    Locator.click!(inc_btn)
    Locator.click!(inc_btn)

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "counter", "2"))
    Expect.to_have_count!(traces, 6)

    Locator.click!(find_switch_tracing_button(dbg_app))

    Locator.click!(inc_btn)
    Locator.click!(inc_btn)

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "counter", "4"))
    Expect.to_have_count!(traces, 6)

    Locator.click!(find_refresh_traces_button(dbg_app))

    Expect.to_have_count!(traces, 10)

    Locator.click!(find_clear_traces_button(dbg_app))

    Expect.to_have_count!(traces, 0)
  end

  test "callback traces have proper execution times displayed", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    traces = find_traces(dbg_app)

    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))

    Page.get_by_role(dev_app, :button, name: "Slow Increment", exact: true) |> Locator.click!()

    refresh_traces_button = find_refresh_traces_button(dbg_app)
    Locator.click!(refresh_traces_button)

    Page.wait_for_timeout!(dbg_app, 405)

    Locator.click!(refresh_traces_button)

    Expect.to_have_count!(traces, 2)

    Expect.to_have_text!(
      Locator.last(traces) |> Locator.locator("span.text-warning-text"),
      ~r/^\s*4\d\d ms\s*$/
    )

    Page.get_by_role(dev_app, :button, name: "Very Slow Increment", exact: true)
    |> Locator.click!()

    Page.wait_for_timeout!(dbg_app, 1110)

    Locator.click!(refresh_traces_button)

    Expect.to_have_count!(traces, 4)

    Expect.to_have_text!(
      Locator.nth(traces, 1) |> Locator.locator("span.text-error-text"),
      ~r/^\s*1\.1\d s\s*$/
    )
  end

  test "settings button exists and redirects works as expected", %{dbg_app: dbg_app} do
    Expect.to_contain_text!(Page.locator(dbg_app, "#traces"), "Callback traces")
    Page.get_by_role(dbg_app, :link, name: "Icon settings") |> Locator.click!()
    Expect.to_have_text!(Page.get_by_role(dbg_app, :heading), "Settings")
    Page.get_by_role(dbg_app, :link, name: "Icon arrow left") |> Locator.click!()
    Expect.to_contain_text!(Page.locator(dbg_app, "#traces"), "Callback traces")
  end

  test "return button redirects to active live views dashboard", %{dbg_app: dbg_app} do
    Expect.to_contain_text!(Page.locator(dbg_app, "#traces"), "Callback traces")
    Page.get_by_role(dbg_app, :link, name: "Icon arrow left") |> Locator.click!()
    Expect.to_be_visible!(Page.get_by_role(dbg_app, :heading, name: "Active LiveViews"))
  end

  test "user can change nodes using node tree and see their assigns and callback traces", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_components_tree_button(dbg_app, "Conditional (5)"))

    Expect.to_contain_text!(find_node_basic_info(dbg_app), "LiveComponent")

    Expect.to_contain_text!(
      find_node_basic_info(dbg_app),
      "LiveDebuggerDev.LiveComponents.Conditional"
    )

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "false"))
    Expect.to_have_count!(find_traces(dbg_app), 2)

    Expect.not_to_be_visible!(find_components_tree_button(dbg_app, "ManyAssigns (15)"))

    Page.locator(dev_app, "#conditional-button") |> Locator.click!()

    Expect.to_be_visible!(find_components_tree_button(dbg_app, "ManyAssigns (15)"))

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "true"))
    Expect.to_have_count!(find_traces(dbg_app), 4)

    Locator.click!(find_components_tree_button(dbg_app, "Conditional (6)"))
    Locator.click!(find_components_tree_button(dbg_app, "Conditional (5)"))

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "true"))
    Expect.to_have_count!(find_traces(dbg_app), 4)

    Page.locator(dev_app, "#conditional-button") |> Locator.click!()

    Expect.not_to_be_visible!(find_components_tree_button(dbg_app, "ManyAssigns (15)"))

    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "false"))
    Expect.to_have_count!(find_traces(dbg_app), 6)
  end

  test "Open in editor shows docs link when envs are not set", %{dbg_app: dbg_app} do
    open_in_editor_link = Page.get_by_role(dbg_app, :link, name: "Open in Editor")
    Expect.to_be_visible!(open_in_editor_link)
    Expect.to_have_attribute!(open_in_editor_link, "href", ~r/open_in_editor\.html/)
  end

  test "user can highlight nodes", %{dev_app: dev_app, dbg_app: dbg_app} do
    Page.locator(dbg_app, "#button-tree-node-2-components-tree") |> Locator.hover!()

    Expect.to_contain_text!(
      find_inspect_tooltip_module_text(dev_app),
      "LiveDebuggerDev.LiveComponents.Name"
    )

    Expect.to_contain_text!(find_inspect_tooltip_type_text(dev_app), "LiveComponent")
    Expect.to_contain_text!(find_inspect_tooltip_value_text(dev_app), "2")
  end

  test "user can copy values", %{dbg_app: dbg_app} do
    Expect.to_contain_text!(
      Page.locator(dbg_app, "#node-inspector-basic-info"),
      "LiveDebuggerDev.LiveViews.Main"
    )

    Page.evaluate!(dbg_app, """
    () => {
      window._copiedText = null;
      navigator.clipboard.writeText = (text) => {
        window._copiedText = text;
        return Promise.resolve();
      };
      document.execCommand = (cmd) => {
        if (cmd === 'copy') {
          const selectedText = window.getSelection()?.toString() ?? '';
          window._copiedText = selectedText;
          return true;
        }
        return false;
      };
    }
    """)

    Page.locator(dbg_app, "button#copy-button-module-name") |> Locator.click!()

    copied_text = Page.evaluate!(dbg_app, "() => window._copiedText")
    assert copied_text == "LiveDebuggerDev.LiveViews.Main"
  end

  test "when user navigates in debugged app, it causes dead view mode", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Expect.to_contain_text!(find_node_basic_info(dbg_app), "LiveDebuggerDev.LiveViews.Main")

    Page.get_by_role(dev_app, :link, name: "Side") |> Locator.click!()

    Expect.to_contain_text!(Page.locator(dbg_app, "#navbar-connected"), "Disconnected")

    Page.get_by_role(dbg_app, :button, name: "Continue") |> Locator.click!()

    Expect.to_contain_text!(find_node_basic_info(dbg_app), "LiveDebuggerDev.LiveViews.Side")
  end

  test "user can inspect arguments of executed callback", %{dev_app: dev_app, dbg_app: dbg_app} do
    traces = find_traces(dbg_app)
    Expect.to_have_count!(traces, 2)

    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#send-button") |> Locator.click!()

    Expect.to_have_count!(traces, 6)

    render3 = Locator.nth(traces, 0)
    handle_info = Locator.nth(traces, 1)
    render2 = Locator.nth(traces, 2)
    handle_event = Locator.nth(traces, 3)
    render1 = Locator.nth(traces, 4)

    Locator.locator(render1, "> summary") |> Locator.click!()
    Expect.to_be_visible!(find_map_entry(render1, "datetime", "nil"))
    Expect.to_be_visible!(find_map_entry(render1, "counter", "0"))

    Locator.locator(handle_event, "> summary") |> Locator.click!()
    Expect.to_contain_text!(handle_event, "handle_event/3")
    Expect.to_contain_text!(handle_event, "increment")

    Locator.locator(render2, "> summary") |> Locator.click!()
    Expect.to_be_visible!(find_map_entry(render2, "datetime", "nil"))
    Expect.to_be_visible!(find_map_entry(render2, "counter", "1"))

    Locator.locator(handle_info, "> summary") |> Locator.click!()
    Expect.to_contain_text!(handle_info, "handle_info/2")
    Expect.to_contain_text!(handle_info, ":new_datetime")

    Locator.locator(render3, "> summary") |> Locator.click!()
    Expect.to_be_visible!(find_map_entry(render3, "datetime", "~U["))
    Expect.to_be_visible!(find_map_entry(render3, "counter", "1"))
  end

  test "incoming traces are filtered by search phrase", %{dev_app: dev_app, dbg_app: dbg_app} do
    traces = find_traces(dbg_app)
    Expect.to_have_count!(traces, 2)

    # Search bar is disabled while tracing is active, stop tracing first
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.fill!(find_search_bar(dbg_app), ":new_datetime")
    Expect.to_have_count!(traces, 0)

    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Expect.to_have_count!(traces, 1)
  end

  test "user can search for callbacks using the searchbar", %{dev_app: dev_app, dbg_app: dbg_app} do
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))

    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Locator.click!(find_switch_tracing_button(dbg_app))

    Locator.fill!(find_search_bar(dbg_app), ":new_datetime")

    traces = find_traces(dbg_app)
    Expect.to_have_count!(traces, 1)
    Expect.to_contain_text!(Locator.first(traces), ":new_datetime")

    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Locator.click!(find_switch_tracing_button(dbg_app))

    Locator.fill!(find_search_bar(dbg_app), "deep value")

    Expect.to_have_count!(traces, 2)

    render_trace = Locator.first(traces)
    Locator.locator(render_trace, "> summary") |> Locator.click!()
    Expect.to_have_count!(Locator.locator(render_trace, "pre", has_text: ~s|"deep value"|), 2)

    find_open_fullscreen_trace_button(dbg_app) |> Locator.first() |> Locator.click!()
    Expect.to_be_visible!(Page.locator(dbg_app, "#trace-fullscreen"))

    Expect.to_have_count!(
      Page.locator(dbg_app, "#trace-fullscreen")
      |> Locator.locator("pre", has_text: ~s|"deep value"|),
      2
    )

    Page.locator(dbg_app, "#trace-fullscreen-close") |> Locator.click!()
    Locator.locator(render_trace, "> summary") |> Locator.click!()

    handle_event_trace = Locator.nth(traces, 1)
    Locator.locator(handle_event_trace, "> summary") |> Locator.click!()

    Expect.to_have_count!(
      Locator.locator(handle_event_trace, "pre", has_text: ~s|"deep value"|),
      1
    )

    find_open_fullscreen_trace_button(dbg_app) |> Locator.first() |> Locator.click!()
    Expect.to_be_visible!(Page.locator(dbg_app, "#trace-fullscreen"))

    Expect.to_have_count!(
      Page.locator(dbg_app, "#trace-fullscreen")
      |> Locator.locator("pre", has_text: ~s|"deep value"|),
      1
    )
  end

  test "user can filter traces by callback name", %{dev_app: dev_app, dbg_app: dbg_app} do
    traces = find_traces(dbg_app)
    Expect.to_have_count!(traces, 2)

    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Page.locator(dev_app, "button#send-button") |> Locator.click!()

    Expect.to_have_count!(traces, 6)
    Locator.click!(find_switch_tracing_button(dbg_app))

    assert_trace_names(dbg_app, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_info/2",
      "render/1",
      "mount/3"
    ])

    Locator.click!(find_filters_button(dbg_app))
    Expect.to_be_visible!(Page.locator(dbg_app, "dialog#filters-fullscreen"))
    Locator.uncheck!(find_callback_checkbox(dbg_app, "mount/3"))
    Locator.uncheck!(find_callback_checkbox(dbg_app, "render/1"))
    Locator.click!(find_apply_button(dbg_app))

    assert_trace_names(dbg_app, ["handle_info/2", "handle_info/2"])

    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Locator.click!(find_refresh_traces_button(dbg_app))

    assert_trace_names(dbg_app, [
      "handle_event/3",
      "handle_event/3",
      "handle_info/2",
      "handle_info/2"
    ])

    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Page.locator(dev_app, "button#send-button") |> Locator.click!()

    assert_trace_names(dbg_app, [
      "handle_info/2",
      "handle_info/2",
      "handle_event/3",
      "handle_event/3",
      "handle_info/2",
      "handle_info/2"
    ])

    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_filters_button(dbg_app))
    Locator.click!(find_reset_all_button(dbg_app))
    Locator.click!(find_apply_button(dbg_app))

    assert_trace_names(dbg_app, [
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

    Locator.click!(find_filters_button(dbg_app))

    for callback <- [
          "mount/3",
          "handle_params/3",
          "handle_info/2",
          "handle_call/3",
          "handle_cast/2",
          "terminate/2",
          "render/1",
          "handle_event/3",
          "handle_async/3"
        ] do
      Locator.uncheck!(find_callback_checkbox(dbg_app, callback))
    end

    Locator.click!(find_apply_button(dbg_app))

    Expect.to_have_count!(traces, 0)
  end

  test "user can filter traces by execution time", %{dev_app: dev_app, dbg_app: dbg_app} do
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))

    Page.locator(dev_app, "button#slow-increment-button") |> Locator.click!()

    refresh_btn = find_refresh_traces_button(dbg_app)
    Locator.click!(refresh_btn)
    Page.wait_for_timeout!(dbg_app, 405)
    Locator.click!(refresh_btn)

    traces = find_traces(dbg_app)
    Expect.to_have_count!(traces, 2)

    Page.locator(dev_app, "button#very-slow-increment-button") |> Locator.click!()
    Page.wait_for_timeout!(dbg_app, 1110)
    Locator.click!(refresh_btn)

    Expect.to_have_count!(traces, 4)

    # Open filters, set exec time min=100ms, max=1s
    Locator.click!(find_filters_button(dbg_app))
    Expect.to_be_visible!(Page.locator(dbg_app, "dialog#filters-fullscreen"))
    Locator.select_option!(find_min_unit_select(dbg_app), "ms")
    Locator.fill!(find_exec_time_min_input(dbg_app), "100")
    Locator.select_option!(find_max_unit_select(dbg_app), "s")
    Locator.fill!(find_exec_time_max_input(dbg_app), "1")
    Locator.click!(find_apply_button(dbg_app))

    # Should show 1 trace (the slow-increment ~400ms)
    Expect.to_have_count!(traces, 1)

    Expect.to_have_text!(
      Locator.first(traces) |> Locator.locator("span.text-warning-text"),
      ~r/^\s*4\d\d ms\s*$/
    )

    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#slow-increment-button") |> Locator.click!()

    # Auto-retry waits for slow trace to appear
    Expect.to_have_count!(traces, 2)

    for i <- 0..1 do
      Expect.to_have_text!(
        Locator.nth(traces, i) |> Locator.locator("span.text-warning-text"),
        ~r/^\s*4\d\d ms\s*$/
      )
    end
  end

  test "user can filter traces by names and execution time", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))

    Page.locator(dev_app, "button#slow-increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#send-button") |> Locator.click!()

    # After clear + re-enable, no mount/initial-render. 3 actions = 6 traces:
    # slow-increment: handle_event + render, increment: handle_event + render, send: handle_info + render
    assert_trace_names(dbg_app, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3"
    ])

    Locator.click!(find_switch_tracing_button(dbg_app))

    # Open filters, set min exec time 100ms, uncheck mount + render, apply
    Locator.click!(find_filters_button(dbg_app))
    Expect.to_be_visible!(Page.locator(dbg_app, "dialog#filters-fullscreen"))
    Locator.select_option!(find_min_unit_select(dbg_app), "ms")
    Locator.fill!(find_exec_time_min_input(dbg_app), "100")
    Locator.uncheck!(find_callback_checkbox(dbg_app, "mount/3"))
    Locator.uncheck!(find_callback_checkbox(dbg_app, "render/1"))
    Locator.click!(find_apply_button(dbg_app))

    # Only the slow handle_event (>100ms) passes
    assert_trace_names(dbg_app, ["handle_event/3"])

    Page.locator(dev_app, "button#slow-increment-button") |> Locator.click!()
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Page.wait_for_timeout!(dbg_app, 405)
    Locator.click!(find_refresh_traces_button(dbg_app))

    # 2 slow handle_events pass the filter
    assert_trace_names(dbg_app, ["handle_event/3", "handle_event/3"])

    Locator.click!(find_filters_button(dbg_app))
    Locator.click!(find_reset_group_button(dbg_app, "execution_time"))
    Locator.click!(find_apply_button(dbg_app))

    # No mount/render, all exec times: handle_info x2, handle_event x3
    assert_trace_names(dbg_app, [
      "handle_info/2",
      "handle_event/3",
      "handle_info/2",
      "handle_event/3",
      "handle_event/3"
    ])

    # Open filters, set exec_time_max=100µs, reset functions group, apply
    Locator.click!(find_filters_button(dbg_app))
    Locator.fill!(find_exec_time_max_input(dbg_app), "100")
    Locator.click!(find_reset_group_button(dbg_app, "functions"))
    Locator.click!(find_apply_button(dbg_app))

    # All callbacks, max 100ms: excludes 2 slow handle_events
    # Total 10 traces - 2 slow = 8: render x5, handle_info x2, handle_event x1
    assert_trace_names(dbg_app, [
      "render/1",
      "handle_info/2",
      "render/1",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1"
    ])

    Locator.click!(find_filters_button(dbg_app))
    Locator.uncheck!(find_callback_checkbox(dbg_app, "handle_info/2"))
    Locator.click!(find_apply_button(dbg_app))

    # Remove handle_info x2: 6 traces
    assert_trace_names(dbg_app, [
      "render/1",
      "render/1",
      "render/1",
      "render/1",
      "handle_event/3",
      "render/1"
    ])

    # Click reset-filters button → all 10 traces shown
    Locator.click!(find_reset_filters_button(dbg_app))

    assert_trace_names(dbg_app, [
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_info/2",
      "render/1",
      "handle_event/3",
      "render/1",
      "handle_event/3"
    ])
  end
end
