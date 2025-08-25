defmodule LiveDebugger.E2E.DeadViewModeTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "dead view mode with navigation and disabled highlighting", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()

    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, true)

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

  defp global_traces(opts), do: css("#global-traces-stream details", opts)

  defp global_callback_traces_button(), do: css("button[aria-label=\"Icon globe\"]")

  defp node_inspector_button(), do: css("button[aria-label=\"Icon info\"]")
end
