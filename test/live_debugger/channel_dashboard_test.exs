defmodule LiveDebugger.ChannelDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can see traces of executed callbacks and updated assigns", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.GenServers.CallbackTracingServer.ping!()

    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(counter_in_assigns(text: "0"))
    |> assert_has(traces(count: 2))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 2))
    |> assert_has(counter_in_assigns(text: "2"))
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 6))
    |> assert_has(counter_in_assigns(text: "4"))
    |> click(toggle_tracing_button())
    |> click(clear_traces_button())
    |> assert_has(traces(count: 0))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 0))
    |> click(refresh_button())
    |> assert_has(traces(count: 4))
  end

  defp first_link(), do: css("#live-sessions a.live-view-link", count: 1)

  defp counter_in_assigns(text: text) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"counter:\")]/../*[contains(normalize-space(text()), \"#{text}\")]"
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)

  defp refresh_button(), do: css("button[phx-click=\"refresh-history\"]")

  defp toggle_tracing_button(), do: css("button[phx-click=\"switch-tracing\"]")

  defp clear_traces_button(), do: css("button[phx-click=\"clear-traces\"]")
end
