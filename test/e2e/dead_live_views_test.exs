defmodule LiveDebugger.E2E.DeadLiveViewsTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, true)
    LiveDebugger.API.SettingsStorage.save(:garbage_collection, true)
    LiveDebugger.API.SettingsStorage.save(:dead_liveviews, false)

    :ok
  end

  @sessions 2
  feature "dead LiveViews are available to debug", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(enable_dead_liveviews_checkbox(selected: false))
    |> refute_has(css("#dead-sessions"))
    |> click(enable_dead_liveviews_toggle())

    Process.sleep(200)

    debugger
    |> assert_text(css("#dead-sessions"), "No dead LiveViews")

    dev_app
    |> visit(@dev_app_url <> "/side")
    |> visit(@dev_app_url)

    debugger
    |> find(dead_sessions(count: 2))
    |> List.first()
    |> click(css("a.live-view-link"))

    Process.sleep(100)

    debugger
    |> assert_text(css("#navbar-connected"), "Disconnected")

    debugger
    |> assert_has(css("label.pointer-events-none", text: "Highlight"))
    |> assert_has(toggle_tracing_button())
  end

  def dead_sessions(opts \\ []), do: css("#dead-sessions > div", opts)

  defp enable_dead_liveviews_toggle() do
    css("label:has(input#dead-liveviews)")
  end

  defp enable_dead_liveviews_checkbox(opts) do
    css("input#dead-liveviews", opts)
  end
end
