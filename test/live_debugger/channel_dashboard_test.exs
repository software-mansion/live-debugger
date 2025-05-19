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

    # Callback traces appear in debugger
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
    |> click(clear_traces_button())

    # Callback traces have proper execution times displayed
    dev_app
    |> click(button("slow-increment-button"))

    debugger
    |> click(refresh_button())
    |> assert_has(traces(count: 0))

    Process.sleep(405)

    execution_time =
      debugger
      |> click(refresh_button())
      |> find(traces(count: 2))
      |> List.last()
      |> find(css("span.text-warning-text"))
      |> Element.text()

    assert execution_time =~ ~r"^40\d ms$"

    debugger
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("very-slow-increment-button"))

    Process.sleep(2505)

    debugger
    |> find(traces(count: 4))
    |> Enum.at(1)
    |> assert_has(css("span.text-error-text", text: "2.50 s"))

    # Filtering callback traces by execution time works
    debugger
    |> click(toggle_tracing_button())
    |> click(filters_button())
    |> fill_in(text_field("exec_time_min"), with: 100)
    |> fill_in(text_field("exec_time_max"), with: 2_000_000)
    |> send_keys([:enter])
    |> find(traces(count: 1))
    |> find(css("span.text-warning-text"))
    |> Element.text()
    |> String.match?(~r"^40\d ms$")

    debugger
    |> click(toggle_tracing_button())

    dev_app
    |> click(button("increment-button"))
    |> click(button("slow-increment-button"))

    Process.sleep(405)

    debugger
    |> find(traces(count: 2))
    |> Enum.each(fn trace ->
      find(trace, css("span.text-warning-text"))
      |> Element.text()
      |> String.match?(~r"^40\d ms$")
    end)
  end

  defp first_link(), do: css("#live-sessions a", count: 1)

  defp counter_in_assigns(text: text) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"counter:\")]/../*[contains(normalize-space(text()), \"#{text}\")]"
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)

  defp refresh_button(), do: css("button[phx-click=\"refresh-history\"]")

  defp toggle_tracing_button(), do: css("button[phx-click=\"switch-tracing\"]")

  defp clear_traces_button(), do: css("button[phx-click=\"clear-traces\"]")

  defp filters_button(), do: css("button[phx-click=\"open\"]")
end
