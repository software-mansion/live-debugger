defmodule LiveDebugger.E2E.DeadViewModeTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, true)
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "dead view mode with navigation and disabled highlighting", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> find(css("#navbar-connected"))
    |> assert_text("Monitored PID")

    dev_app
    |> execute_script("window.location.reload();")

    Process.sleep(200)

    debugger
    |> find(css("#navbar-connected"))
    |> assert_text("Disconnected")

    debugger
    |> assert_has(css("#components-tree"))
    |> click(button("Crash (3)"))

    Process.sleep(200)

    debugger
    |> find(sidebar_basic_info())
    |> assert_text("LiveDebuggerDev.LiveComponents.Crash")

    debugger
    |> assert_has(css("label.pointer-events-none", text: "Highlight"))
    |> click(global_callback_traces_button())
    |> assert_has(global_traces(count: 25))
    |> click(node_inspector_button())
    |> assert_has(css("label.pointer-events-none", text: "Highlight"))
  end

  @sessions 2
  feature "traces ended with exception are visible in dead view mode", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> click(global_callback_traces_button())
    |> click(clear_traces_button())
    |> click(toggle_tracing_button())

    dev_app
    |> click(css("button[phx-click=\"crash\"]"))

    Process.sleep(200)

    debugger
    |> assert_has(global_traces_with_error(count: 1))
  end

  defp global_traces(opts), do: css("#global-traces-stream details", opts)

  defp global_traces_with_error(opts) do
    css("#global-traces-stream details.border-error-icon", opts)
  end

  defp global_callback_traces_button(), do: css("button[aria-label=\"Icon globe\"]")

  defp node_inspector_button(), do: css("button[aria-label=\"Icon info\"]")
end
