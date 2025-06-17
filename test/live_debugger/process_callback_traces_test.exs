defmodule LiveDebugger.ProcessCallbackTracesTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can trace callbacks globally", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    dev_app
    |> visit(@dev_app_url)

    Process.sleep(200)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(global_callback_traces_button())
    |> assert_has(title(text: "Global Callback Traces"))
    |> assert_has(traces(count: 25))
    |> click(clear_traces_button())
    |> assert_has(traces(count: 0))
    |> assert_has(no_traces_info())
    |> click(toggle_tracing_button())

    dev_app
    |> click(css("button#send-button"))

    Process.sleep(200)

    debugger
    |> click(toggle_tracing_button())
    |> assert_has(traces(count: 3))
    |> assert_has(trace_name(text: "handle_event/3", count: 1))
    |> assert_has(trace_name(text: "handle_info/2", count: 1))
    |> assert_has(trace_name(text: "render/1", count: 1))
    |> assert_has(trace_module(text: "LiveDebuggerDev.LiveViews.Main", count: 2))
    |> assert_has(trace_module(text: "LiveDebuggerDev.LiveComponents.Send (4)", count: 1))
    |> click(clear_traces_button())
    |> assert_has(traces(count: 0))
    |> assert_has(no_traces_info())

    dev_app
    |> click(css("button#increment-button"))

    Process.sleep(200)

    debugger
    |> click(refresh_history_button())
    |> assert_has(traces(count: 2))
    |> assert_has(trace_name(text: "handle_event/3", count: 1))
    |> assert_has(trace_name(text: "render/1", count: 1))
  end

  defp traces(opts), do: css("#global-traces-stream details", opts)

  defp trace_name(opts), do: css("#global-traces-stream details p.font-medium", opts)

  defp trace_module(opts), do: css("#global-traces-stream details div.col-span-3", opts)

  defp global_callback_traces_button(), do: css("button[aria-label=\"Icon globe\"]")
end
