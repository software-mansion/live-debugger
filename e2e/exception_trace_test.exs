defmodule LiveDebugger.E2E.ExceptionTraceTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp find_global_traces(page), do: Page.locator(page, "#global-traces-stream details")

  defp find_global_callback_traces_button(page),
    do: Page.locator(page, "#global-traces-navbar-item a")

  defp find_crash_module(page),
    do:
      Page.locator(
        page,
        ~s|button[phx-value-module="Elixir.LiveDebuggerDev.LiveComponents.Crash"]|
      )

  defp find_handle_event_filter_checkbox(page, type),
    do: Page.locator(page, ~s|input[id="filters-#{type}-form_handle_event/3"]|)

  defp find_apply_button(page), do: Page.get_by_role(page, :button, name: "Apply", exact: true)

  defp find_error_button(page, action), do: Page.locator(page, ~s|button[phx-click="#{action}"]|)

  defp fill_search_input(page, text) do
    input = Page.locator(page, "#trace-search-input")
    Locator.fill!(input, text)
  end

  defp assert_trace_exception(dbg_app, error_name, stacktrace_content) do
    traces = find_global_traces(dbg_app)
    Expect.to_have_count!(traces, 1)
    trace = Locator.first(traces)
    Locator.locator(trace, "summary") |> Locator.click!()

    Expect.to_be_visible!(Locator.locator(trace, "summary.bg-error-bg"))
    Expect.to_contain_text!(Locator.locator(trace, "summary .text-error-text"), error_name)

    Locator.locator(trace, "label", has_text: "Stacktrace") |> Locator.click!()
    Expect.to_contain_text!(Locator.get_by_test_id(trace, "stacktrace"), stacktrace_content)

    Locator.get_by_text(trace, "Raw Error") |> Locator.click!()
    Expect.to_contain_text!(Locator.get_by_test_id(trace, "raw_error"), error_name)
    Expect.to_contain_text!(Locator.get_by_test_id(trace, "raw_error"), "terminating")
  end

  defp navigate_to_new_process(dbg_app) do
    Page.get_by_role(dbg_app, :button, name: "Continue") |> Locator.click!()

    Locator.click!(find_global_callback_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
  end

  defp test_exception(dev_app, dbg_app, crash_name, error_name, stacktrace_content) do
    Test.step "Testing exception: #{crash_name}" do
      Locator.click!(find_error_button(dev_app, crash_name))
      assert_trace_exception(dbg_app, error_name, stacktrace_content)
      navigate_to_new_process(dbg_app)
    end
  end

  test "debugger captures runtime errors and exceptions in global callbacks 1", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_global_callback_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))

    exceptions = [
      {"crash_argument", "ArgumentError", "invalid_integer"},
      {"crash_match", "MatchError", "dev/live_components/crash"},
      {"crash_case", "CaseClauseError", "dev/live_components/crash"},
      {"crash_exit", ":exit_reason", "(Stacktrace not available)"}
    ]

    for {crash_name, error_name, stacktrace_content} <- exceptions do
      test_exception(dev_app, dbg_app, crash_name, error_name, stacktrace_content)
    end
  end

  test "debugger captures runtime errors and exceptions in global callbacks 2", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_global_callback_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))

    exceptions = [
      {"crash_throw", "{:bad_return_value, :throw_value}", "(Stacktrace not available)"},
      {"crash_function_clause", "FunctionClauseError", "private_function(:error)"},
      {"crash_undefined", "UndefinedFunctionError", "this_function_does_not_exist"},
      {"crash_arithmetic", "ArithmeticError", "dev/live_components/crash"}
    ]

    for {crash_name, error_name, stacktrace_content} <- exceptions do
      test_exception(dev_app, dbg_app, crash_name, error_name, stacktrace_content)
    end
  end

  test "debugger captures runtime errors and exceptions in global callbacks 3", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_global_callback_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))
    Locator.click!(find_clear_traces_button(dbg_app))
    Locator.click!(find_switch_tracing_button(dbg_app))

    exceptions = [
      {"crash_linked", "RuntimeError", "dev/live_components/crash"},
      {"crash_protocol", "Protocol.UndefinedError", "dev/live_components/crash"},
      {"crash_key", "KeyError", "dev/live_components/crash"},
      {"crash_bad_return", "ArgumentError", "lib/phoenix_live_view/channel"}
    ]

    for {crash_name, error_name, stacktrace_content} <- exceptions do
      test_exception(dev_app, dbg_app, crash_name, error_name, stacktrace_content)
    end
  end

  describe "exception appears in currently inspected node" do
    test "should not show flash message during crash of currently inspected node", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_node_inspector_button(dbg_app))
      Locator.click!(find_crash_module(dbg_app))
      Locator.click!(find_error_button(dev_app, "crash_argument"))

      flash = Page.locator(dbg_app, "#flash-error")
      Expect.not_to_be_visible!(flash)
    end

    test "should show flash message when exception trace is hidden by active filters", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_node_inspector_button(dbg_app))
      Locator.click!(find_crash_module(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))
      Locator.click!(find_filters_button(dbg_app))
      Locator.click!(find_handle_event_filter_checkbox(dbg_app, "fullscreen"))
      Locator.click!(find_apply_button(dbg_app))
      Locator.click!(find_switch_tracing_button(dbg_app))

      Locator.click!(find_error_button(dev_app, "crash_argument"))

      assert_crash_flash(dbg_app)
    end

    test "should show flash message when exception trace is hidden by active search phrase", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_node_inspector_button(dbg_app))
      Locator.click!(find_crash_module(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))
      fill_search_input(dbg_app, "123456789")
      Locator.click!(find_switch_tracing_button(dbg_app))
      Locator.click!(find_error_button(dev_app, "crash_argument"))

      assert_crash_flash(dbg_app)
    end
  end

  test "should show flash message when a non-inspected node crashes", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Locator.click!(find_node_inspector_button(dbg_app))
    Locator.click!(find_error_button(dev_app, "crash_argument"))

    assert_crash_flash(dbg_app)
  end

  describe "exception inspected in global callbacks" do
    test "should not show flash when no filter and no search phrase are applied", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_global_callback_traces_button(dbg_app))

      Locator.click!(find_error_button(dev_app, "crash_argument"))

      flash = Page.locator(dbg_app, "#flash-error")
      Expect.not_to_be_visible!(flash)
    end

    test "should show flash message when exception trace is hidden by active filters", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_global_callback_traces_button(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))
      Locator.click!(find_handle_event_filter_checkbox(dbg_app, "sidebar"))
      Locator.click!(find_apply_button(dbg_app))
      Locator.click!(find_switch_tracing_button(dbg_app))
      Locator.click!(find_error_button(dev_app, "crash_argument"))

      assert_crash_flash(dbg_app)
    end

    test "should show flash message when exception trace is hidden by active search phrase", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(find_global_callback_traces_button(dbg_app))

      Locator.click!(find_switch_tracing_button(dbg_app))
      fill_search_input(dbg_app, "123456789")
      Locator.click!(find_switch_tracing_button(dbg_app))
      Locator.click!(find_error_button(dev_app, "crash_argument"))

      assert_crash_flash(dbg_app)
    end
  end

  # The flash assertions repeated in the original tests.
  defp assert_crash_flash(dbg_app) do
    flash = Page.locator(dbg_app, "#flash-error")
    Expect.to_be_visible!(flash)
    Expect.to_contain_text!(flash, "LiveComponent crashed.")
    Expect.to_contain_text!(flash, "LiveDebuggerDev.LiveComponents.Crash")
    Expect.to_contain_text!(flash, "Open in Node Inspector")
  end
end
