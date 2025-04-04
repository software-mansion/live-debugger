defmodule LiveDebugger.DevAppTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  @dev_app_url LiveDebuggerDev.Endpoint.url()

  setup :unset_mocks

  feature "user can visit dev page", %{session: session} do
    session
    |> visit(@dev_app_url)
    |> assert_has(css("main > div > span", text: "Main [LiveView]"))
    |> assert_has(button("increment"))
    |> assert_has(button("update"))
    |> assert_has(button("send"))

    session
    |> visit(@dev_app_url <> "/side")
    |> assert_has(css("main > div > span", text: "Side [LiveView]"))

    session
    |> visit(@dev_app_url <> "/nested")
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))

    session
    |> visit(@dev_app_url <> "/messages")
    |> assert_has(css("main > div > span", text: "Messages [LiveView]"))

    session
    |> visit(@dev_app_url <> "/embedded")
    |> assert_has(css("main > div > span", count: 3))

    session
    |> visit(@dev_app_url <> "/embedded_in_controller")
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))
  end
end
