defmodule LiveDebugger.ChannelDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 2
  feature "user can see traces of executed callbacks and updated assigns", %{
    sessions: [dev_app, debugger]
  } do
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
    |> click(button("toggle-tracing"))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 6))
    |> assert_has(counter_in_assigns(text: "4"))
    |> click(button("toggle-tracing"))
    |> click(button("clear-traces"))
    |> assert_has(traces(count: 0))

    dev_app
    |> click(button("increment-button"))
    |> click(button("increment-button"))

    debugger
    |> assert_has(traces(count: 0))
    |> click(button("refresh"))
    |> assert_has(traces(count: 4))
  end

  defp first_link(), do: css("#live-sessions a", count: 1)

  defp counter_in_assigns(text: text) do
    xpath(
      ".//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"counter:\")]/../*[contains(normalize-space(text()), \"#{text}\")]"
    )
  end

  defp traces(opts), do: css("#traces-list-stream details", opts)
end
