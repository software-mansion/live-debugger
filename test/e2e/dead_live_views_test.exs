defmodule LiveDebugger.E2E.DeadLiveViewsTest do
  use LiveDebugger.E2ECase

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.UserChangedSettings

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:dead_view_mode, true)
    LiveDebugger.API.SettingsStorage.save(:garbage_collection, true)
    LiveDebugger.API.SettingsStorage.save(:dead_liveviews, false)

    Bus.Impl.broadcast_event!(%UserChangedSettings{
      key: :garbage_collection,
      value: true,
      from: self()
    })

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
    |> refute_has(css("#dead-sessions"))
    |> click(toggle_dead_liveviews_collapsible())
    |> find(css("#dead-sessions"))
    |> assert_text("No dead LiveViews")

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

  defp toggle_dead_liveviews_collapsible() do
    css("div[phx-click=\"toggle-dead-liveviews\"]")
  end
end
