defmodule LiveDebugger.E2E.GlobalTracesTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "user can trace callbacks globally", %{
    sessions: [dev_app, debugger]
  } do
    visit(dev_app, @dev_app_url)
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

    click(dev_app, css("button#send-button"))
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

    click(dev_app, css("button#increment-button"))
    Process.sleep(200)

    debugger
    |> click(refresh_history_button())
    |> assert_has(traces(count: 2))
    |> assert_has(trace_name(text: "handle_event/3", count: 1))
    |> assert_has(trace_name(text: "render/1", count: 1))
  end

  @sessions 2
  feature "user can go to specific node from global callbacks", %{
    sessions: [dev_app, debugger]
  } do
    visit(dev_app, @dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(global_callback_traces_button())
    |> assert_has(title(text: "Global Callback Traces"))
    |> click(clear_traces_button())
    |> click(toggle_tracing_button())

    click(dev_app, css("button#send-button"))

    debugger
    |> find(trace_module(text: "LiveDebuggerDev.LiveViews.Main", count: 2))
    |> List.first()
    |> click(link("LiveDebuggerDev.LiveViews.Main"))

    debugger
    |> find(sidebar_basic_info())
    |> assert_text("LiveView")
    |> assert_text("LiveDebuggerDev.LiveViews.Main")

    debugger
    |> click(global_callback_traces_button())
    |> find(trace_module(text: "LiveDebuggerDev.LiveComponents.Send (4)"))
    |> click(link("LiveDebuggerDev.LiveComponents.Send (4)"))

    debugger
    |> find(sidebar_basic_info())
    |> assert_text("LiveComponent")
    |> assert_text("LiveDebuggerDev.LiveComponents.Send")
  end

  @sessions 2
  feature "user can search for callbacks using the searchbar", %{
    sessions: [dev_app, debugger]
  } do
    visit(dev_app, @dev_app_url)
    Process.sleep(200)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(global_callback_traces_button())
    |> assert_has(title(text: "Global Callback Traces"))
    |> assert_has(traces(count: 25))
    |> click(toggle_tracing_button())

    click(dev_app, button("send-button"))
    Process.sleep(200)

    click(debugger, toggle_tracing_button())

    debugger
    |> fill_in(search_bar(), with: ":new_datetime")
    |> find(traces(count: 1), fn trace -> assert_text(trace, ":new_datetime") end)
    |> click(clear_traces_button())

    click(dev_app, button("increment-button"))

    [render_trace, handle_event_trace] =
      debugger
      |> fill_in(search_bar(), with: "deep value")
      |> find(traces(count: 2))

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
    visit(dev_app, @dev_app_url)
    Process.sleep(200)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(global_callback_traces_button())
    |> assert_has(title(text: "Global Callback Traces"))
    |> assert_has(traces(count: 25))
    |> fill_in(search_bar(), with: ":new_datetime")
    |> click(toggle_tracing_button())

    click(dev_app, button("send-button"))
    Process.sleep(200)

    assert_has(debugger, traces(count: 1))
  end

  defp traces(opts), do: css("#global-traces-stream details", opts)

  defp trace_name(opts), do: css("#global-traces-stream details p.font-medium", opts)

  defp trace_module(opts), do: css("#global-traces-stream details div.col-span-3", opts)

  defp global_callback_traces_button, do: css("button[aria-label=\"Icon globe\"]")

  defp open_fullscreen_trace_button, do: css("button[phx-click=\"open-trace\"]")
end
