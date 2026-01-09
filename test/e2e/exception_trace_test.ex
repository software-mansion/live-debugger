defmodule LiveDebugger.E2E.ExceptionTraceTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)
    Application.put_env(:wallaby, :js_errors, false)

    on_exit(fn ->
      Application.put_env(:wallaby, :js_errors, true)
    end)

    :ok
  end

  @sessions 2
  feature "debugger captures runtime errors and exceptions in global callbacks", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> select_live_view()
    |> click(global_callback_traces_button())
    |> click(clear_traces_button())
    |> click(toggle_tracing_button())

    test_exception(dev_app, debugger, "crash_argument", "ArgumentError", "invalid_integer")
    test_exception(dev_app, debugger, "crash_match", "MatchError", "dev/live_components/crash")

    test_exception(
      dev_app,
      debugger,
      "crash_case",
      "CaseClauseError",
      "dev/live_components/crash"
    )

    test_exception(dev_app, debugger, "crash_exit", ":exit_reason", "(Stacktrace not available)")

    test_exception(
      dev_app,
      debugger,
      "crash_throw",
      "{:bad_return_value, :throw_value}",
      "(Stacktrace not available)"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_function_clause",
      "FunctionClauseError",
      "private_function(:error)"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_undefined",
      "UndefinedFunctionError",
      "this_function_does_not_exist"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_arithmetic",
      "ArithmeticError",
      "dev/live_components/crash"
    )
  end

  @sessions 2
  feature "debugger captures runtime errors and exceptions in global callbacks pt.2", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> select_live_view()
    |> click(global_callback_traces_button())
    |> click(clear_traces_button())
    |> click(toggle_tracing_button())

    test_exception(
      dev_app,
      debugger,
      "crash_linked",
      "RuntimeError",
      "dev/live_components/crash"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_protocol",
      "Protocol.UndefinedError",
      "dev/live_components/crash"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_key",
      "KeyError",
      "dev/live_components/crash"
    )

    test_exception(
      dev_app,
      debugger,
      "crash_bad_return",
      "ArgumentError",
      "lib/phoenix_live_view/channel"
    )
  end

  defp test_exception(dev_app, debugger, crash_name, error_name, stacktrace_content) do
    dev_app
    |> click(error_button(crash_name))

    debugger
    |> assert_trace_exception(error_name, stacktrace_content)

    debugger
    |> navigate_to_new_process()
  end

  defp assert_trace_exception(session, error_name, stacktrace_content) do
    trace =
      session
      |> assert_has(traces(count: 1))
      |> find(traces(count: 1))
      |> take_screenshot()
      |> click(css("summary"))

    trace
    |> assert_has(css("summary.bg-error-bg"))
    |> assert_has(trace_summary_error(error_name))

    trace
    |> click(tab_label("Stacktrace"))
    |> assert_has(trace_content_pre(stacktrace_content))

    trace
    |> click(tab_label("Raw Error"))
    |> assert_has(trace_content_pre(error_name))
    |> assert_has(trace_content_pre("terminating"))
  end

  defp navigate_to_new_process(session) do
    session
    |> click(css("button", text: "Continue"))

    session
    |> click(global_callback_traces_button())
    |> click(clear_traces_button())
    |> click(toggle_tracing_button())
  end

  defp global_callback_traces_button(), do: css("#global-traces-navbar-item a")

  defp tab_label(text) do
    css("label", text: text)
  end

  defp trace_content_pre(text) do
    css("pre", text: text, visible: true)
  end

  defp trace_summary_error(text) do
    css("summary .text-error-text", text: text)
  end

  defp error_button(action), do: css("button[phx-click=\"#{action}\"]")

  defp traces(opts), do: css("#global-traces-stream details", opts)

  defp trace_name(opts), do: css("#global-traces-stream details p.font-medium", opts)
  defp trace_module(opts), do: css("#global-traces-stream details div.col-span-3", opts)
end
