defmodule LiveDebugger.ChannelDashboardTest do
  use ExUnit.Case
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  @dev_app_url LiveDebuggerDev.Endpoint.url()

  setup :unset_mocks

  @sessions 2
  feature "user can see traces of executed callbacks and updated assigns", %{
    sessions: [dev_session, lvdbg_session]
  } do
    dev_session
    |> visit(@dev_app_url)

    lvdbg_session
    |> visit("/")
    |> click(first_link())
    |> assert_has(counter_in_assigns(text: "0"))

    dev_session
    |> click(button("increment"))
    |> click(button("increment"))

    lvdbg_session
    |> assert_has(traces(count: 0))
    |> assert_has(counter_in_assigns(text: "2"))
    |> click(button("toggle-tracing"))

    dev_session
    |> click(button("increment"))
    |> click(button("increment"))

    lvdbg_session
    |> assert_has(traces(count: 4))
    |> assert_has(counter_in_assigns(text: "4"))
    |> click(button("toggle-tracing"))
    |> click(button("clear-traces"))
    |> assert_has(traces(count: 0))

    dev_session
    |> click(button("increment"))
    |> click(button("increment"))

    lvdbg_session
    |> assert_has(traces(count: 0))
    |> click(button("refresh"))
    |> assert_has(traces(count: 4))
  end

  defp first_link(), do: css("#live-sessions a", count: 1)

  defp counter_in_assigns(text: text),
    do: css("#assigns ol li:nth-child(2) span:nth-child(3)", text: text)

  defp traces(count: count), do: css("#traces-list-stream details", count: count)
end
