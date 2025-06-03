defmodule LiveDebugger.WindowDashboardTest do
  use LiveDebugger.E2ECase

  @sessions 3
  feature "user can see only active live views per window", %{
    sessions: [dev_app1, dev_app2, debugger]
  } do
    dev_app1
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))

    transport_pid = get_transport_pid(debugger)

    debugger
    |> visit("/transport_pid/#{transport_pid}")
    |> assert_has(title(text: "Active LiveViews in a single window"))
    |> assert_has(live_sessions(count: 1))

    dev_app2
    |> visit(@dev_app_url)

    debugger
    |> click(refresh_button())
    |> assert_has(live_sessions(count: 1))

    debugger
    |> click(return_button())
    |> assert_has(title(text: "Active LiveViews"))
    |> assert_has(live_sessions(count: 1))
  end

  @sessions 2
  feature "settings button exists and redirects works as expected", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url)

    transport_pid = get_transport_pid(debugger)

    debugger
    |> visit("/transport_pid/#{transport_pid}")
    |> assert_has(title(text: "Active LiveViews in a single window"))
    |> assert_has(settings_button())
    |> click(settings_button())
    |> assert_has(css("h1", text: "Settings"))
    |> assert_has(return_button())
    |> click(return_button())
    |> assert_has(title(text: "Active LiveViews in a single window"))
  end

  @sessions 2
  feature "return button does not exist in case of iframe", %{
    sessions: [dev_app, debugger]
  } do
    LiveDebugger.MockIframeCheck
    |> stub(:on_mount, fn _, _, _, socket ->
      {:cont, Phoenix.Component.assign(socket, :in_iframe?, true)}
    end)

    dev_app
    |> visit(@dev_app_url)

    transport_pid = get_transport_pid(debugger)

    debugger
    |> visit("/transport_pid/#{transport_pid}")
    |> assert_has(title(text: "Active LiveViews in a single window"))
    |> refute_has(return_button())
  end

  defp title(text: text), do: css("h1", text: text)

  defp live_sessions(count: count), do: css("#live-sessions ", count: count)

  defp get_transport_pid(debugger) do
    debugger
    |> visit("/")
    |> find(css("#live-sessions .transport-pid"))
    |> Element.text()
  end

  defp refresh_button(), do: css("button[phx-click=\"refresh\"]")

  defp return_button(), do: css("navbar a#return-button")

  defp settings_button(), do: css("navbar a#settings-button")
end
