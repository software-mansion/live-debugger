defmodule LiveDebugger.E2E.GlobalTracesTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp global_traces_title(page, text), do: Page.locator(page, "h1", has_text: text)

  defp no_traces_info(page),
    do:
      Page.locator(page, "#global-traces-stream-empty",
        has_text: "No traces have been recorded yet."
      )

  defp find_global_traces(page), do: Page.locator(page, "#global-traces-stream details")

  defp trace_name(page, text),
    do: Page.locator(page, "#global-traces-stream details p.font-medium", has_text: text)

  defp trace_module(page, text),
    do: Page.locator(page, "#global-traces-stream details div.col-span-3", has_text: text)

  defp search_bar(page), do: Page.locator(page, "#trace-search-input")
  defp trace_fullscreen(page), do: Page.locator(page, "#trace-fullscreen")
  defp open_fullscreen_button(page), do: Page.locator(page, ~s|button[phx-click="open-trace"]|)

  defp trace_diffs_checkbox(page),
    do: Page.locator(page, "#filters-sidebar-form #filters-sidebar-form_trace_diffs")

  defp apply_button(page),
    do: Page.locator(page, ~s|#filters-sidebar-form button[type="submit"]|, has_text: "Apply")

  defp reset_all_button(page),
    do: Page.locator(page, "#filters-sidebar-form button", has_text: "Reset all")

  defp filters_sidebar(page), do: Page.locator(page, "#filters-sidebar")

  defp main_traces(page) do
    Page.locator(page, "#global-traces-stream details div.col-span-3")
    |> Locator.filter(has_text: "LiveDebuggerDev.LiveViews.Main")
  end

  test "user can trace callbacks globally", %{dev_app: dev_app, dbg_app: dbg_app} do
    Locator.click!(find_global_traces_navbar_item(dbg_app))
    Expect.to_be_visible!(global_traces_title(dbg_app, "Global Callback Traces"))

    Expect.to_have_count!(find_global_traces(dbg_app), 25)

    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Expect.to_have_count!(find_global_traces(dbg_app), 0)
    Expect.to_be_visible!(no_traces_info(dbg_app))

    Locator.click!(find_switch_tracing_button(dbg_app))
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Locator.click!(find_switch_tracing_button(dbg_app))

    traces = find_global_traces(dbg_app)
    Expect.to_have_count!(traces, 3)
    Expect.to_have_count!(trace_name(dbg_app, "handle_event/3"), 1)
    Expect.to_have_count!(trace_name(dbg_app, "handle_info/2"), 1)
    Expect.to_have_count!(trace_name(dbg_app, "render/1"), 1)

    Expect.to_have_count!(trace_module(dbg_app, "LiveDebuggerDev.LiveViews.Main"), 2)
    Expect.to_have_count!(trace_module(dbg_app, "LiveDebuggerDev.LiveComponents.Send (4)"), 1)

    Locator.click!(find_clear_traces_button(dbg_app))
    Expect.to_have_count!(find_global_traces(dbg_app), 0)
    Expect.to_be_visible!(no_traces_info(dbg_app))

    Page.locator(dev_app, "button#increment-button") |> Locator.click!()

    Locator.click!(find_refresh_traces_button(dbg_app))
    Expect.to_have_count!(find_global_traces(dbg_app), 2)
    Expect.to_have_count!(trace_name(dbg_app, "handle_event/3"), 1)
    Expect.to_have_count!(trace_name(dbg_app, "render/1"), 1)
  end

  test "user can go to specific node from global callbacks", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_global_traces_navbar_item(dbg_app))
    restart_tracing(dbg_app)
    Page.locator(dev_app, "button#send-button") |> Locator.click!()

    Page.get_by_role(dbg_app, :link, name: "LiveDebuggerDev.LiveViews.Main", exact: true)
    |> Locator.first()
    |> Locator.click!()

    Expect.to_contain_text!(find_sidebar_basic_info(dbg_app), "LiveView")
    Expect.to_contain_text!(find_sidebar_basic_info(dbg_app), "LiveDebuggerDev.LiveViews.Main")

    Locator.click!(find_global_traces_navbar_item(dbg_app))

    Page.get_by_role(dbg_app, :link, name: "LiveDebuggerDev.LiveComponents.Send (4)", exact: true)
    |> Locator.first()
    |> Locator.click!()

    Expect.to_contain_text!(find_sidebar_basic_info(dbg_app), "LiveComponent")

    Expect.to_contain_text!(
      find_sidebar_basic_info(dbg_app),
      "LiveDebuggerDev.LiveComponents.Send"
    )
  end

  test "user can search for callbacks using the searchbar", %{dev_app: dev_app, dbg_app: dbg_app} do
    Locator.click!(find_global_traces_navbar_item(dbg_app))
    restart_tracing(dbg_app)
    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Locator.click!(find_switch_tracing_button(dbg_app))

    Locator.fill!(search_bar(dbg_app), ":new_datetime")
    Expect.to_have_count!(find_global_traces(dbg_app), 1)

    Locator.click!(find_clear_traces_button(dbg_app))
    Page.locator(dev_app, "button#increment-button") |> Locator.click!()

    Locator.fill!(search_bar(dbg_app), "deep value")
    Page.wait_for_timeout!(dbg_app, 250)

    traces = find_global_traces(dbg_app)
    Expect.to_have_count!(traces, 2)

    render_trace = Locator.first(traces)
    Locator.locator(render_trace, "summary") |> Locator.click!()
    Expect.to_have_count!(Locator.locator(render_trace, "pre", has_text: ~s|"deep value"|), 2)

    open_fullscreen_button(dbg_app) |> Locator.first() |> Locator.click!()
    Expect.to_be_visible!(trace_fullscreen(dbg_app))

    Expect.to_have_count!(
      Locator.locator(trace_fullscreen(dbg_app), "pre", has_text: ~s|"deep value"|),
      2
    )

    Page.locator(dbg_app, "#trace-fullscreen-close") |> Locator.click!()
  end

  test "incoming traces are filtered by search phrase", %{dev_app: dev_app, dbg_app: dbg_app} do
    Locator.click!(find_global_traces_navbar_item(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))

    Locator.fill!(search_bar(dbg_app), ":new_datetime")
    Locator.click!(find_switch_tracing_button(dbg_app))

    Page.locator(dev_app, "button#send-button") |> Locator.click!()
    Expect.to_have_count!(find_global_traces(dbg_app), 1)
  end

  test "user can enable diff tracing and see diff traces", %{dev_app: dev_app, dbg_app: dbg_app} do
    Page.set_viewport_size!(dbg_app, %{width: 1920, height: 1080})
    Locator.click!(find_global_traces_navbar_item(dbg_app))
    Expect.to_be_visible!(global_traces_title(dbg_app, "Global Callback Traces"))

    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Expect.to_have_count!(find_global_traces(dbg_app), 0)
    Expect.to_be_visible!(no_traces_info(dbg_app))
    Expect.to_be_visible!(filters_sidebar(dbg_app))

    Locator.check!(trace_diffs_checkbox(dbg_app))
    Locator.click!(apply_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))

    Page.locator(dev_app, "button#increment-button") |> Locator.click!()

    Locator.click!(find_switch_tracing_button(dbg_app))

    traces = find_global_traces(dbg_app)
    Expect.to_have_count!(traces, 3)
    Expect.to_be_visible!(trace_name(dbg_app, "handle_event/3"))
    Expect.to_be_visible!(trace_name(dbg_app, "render/1"))
    Expect.to_be_visible!(trace_name(dbg_app, "Diff sent"))

    diff_trace = traces |> Locator.filter(has_text: "Diff sent") |> Locator.first()
    Locator.locator(diff_trace, "summary") |> Locator.click!()

    Expect.to_be_visible!(
      Locator.locator(diff_trace, "pre", has_text: ~s|"diff"|)
      |> Locator.nth(1)
    )

    open_fullscreen_button(dbg_app) |> Locator.first() |> Locator.click!()
    Expect.to_be_visible!(trace_fullscreen(dbg_app))

    Expect.to_be_visible!(
      Locator.locator(trace_fullscreen(dbg_app), "pre", has_text: ~s|"diff"|)
      |> Locator.nth(1)
    )

    Page.locator(dbg_app, "#trace-fullscreen-close") |> Locator.click!()
    Expect.to_be_hidden!(trace_fullscreen(dbg_app))
  end

  describe "Global Traces Filtering" do
    setup %{dbg_app: dbg_app} do
      Locator.click!(find_global_traces_navbar_item(dbg_app))
      restart_tracing(dbg_app)
      :ok
    end

    test "user can filter existing traces by component", %{dev_app: dev_app, dbg_app: dbg_app} do
      Page.locator(dev_app, "button#increment-button") |> Locator.click!()
      Expect.not_to_have_count!(find_global_traces(dbg_app), 0)

      traces = main_traces(dbg_app)

      Expect.to_have_count!(traces, 2)

      Locator.click!(find_switch_tracing_button(dbg_app))

      main_label =
        Page.locator(dbg_app, "#filters-sidebar label",
          has_text: "LiveDebuggerDev.LiveViews.Main"
        )

      checkbox_id = Locator.get_attribute!(main_label, "for")
      Page.locator(dbg_app, ~s|[id="#{checkbox_id}"]|) |> Locator.uncheck!()

      Locator.click!(apply_button(dbg_app))

      Expect.to_have_count!(traces, 0)
    end

    test "new traces are filtered out when component is unchecked", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_switch_tracing_button(dbg_app))

      main_label =
        Page.locator(dbg_app, "#filters-sidebar label",
          has_text: "LiveDebuggerDev.LiveViews.Main"
        )

      checkbox_id = Locator.get_attribute!(main_label, "for")

      Page.locator(dbg_app, ~s|[id="#{checkbox_id}"]|) |> Locator.uncheck!()
      Locator.click!(apply_button(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))

      Page.locator(dev_app, "button#increment-button") |> Locator.click!()

      Expect.to_have_count!(find_global_traces(dbg_app), 0)
    end

    test "reset all button restores all component filters and shows hidden traces", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_switch_tracing_button(dbg_app))

      main_label =
        Page.locator(dbg_app, "#filters-sidebar label",
          has_text: "LiveDebuggerDev.LiveViews.Main"
        )

      checkbox_id = Locator.get_attribute!(main_label, "for")
      checkbox = Page.locator(dbg_app, ~s|[id="#{checkbox_id}"]|)

      Locator.uncheck!(checkbox)
      Locator.click!(apply_button(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))
      Page.locator(dev_app, "button#increment-button") |> Locator.click!()

      Expect.to_have_count!(main_traces(dbg_app), 0)

      Locator.click!(find_switch_tracing_button(dbg_app))
      Expect.to_be_visible!(reset_all_button(dbg_app))
      Locator.click!(reset_all_button(dbg_app))

      Expect.to_be_checked!(checkbox)

      if Locator.is_enabled!(apply_button(dbg_app)) do
        Locator.click!(apply_button(dbg_app))
      end

      Locator.click!(find_switch_tracing_button(dbg_app))
      traces_after_reset = main_traces(dbg_app)

      Expect.not_to_have_count!(traces_after_reset, 0)
      count = Locator.count!(traces_after_reset)

      for i <- 0..(count - 1)//1 do
        Expect.to_be_visible!(Locator.nth(traces_after_reset, i))
      end
    end
  end
end
