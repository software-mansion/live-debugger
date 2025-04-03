defmodule LiveDebugger.DevAppTest do
  use ExUnit.Case
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  @dev_app_url LiveDebuggerDev.Endpoint.url()

  setup :unset_mocks

  feature "user can visit Main page", %{session: session} do
    session
    |> visit(@dev_app_url)
    |> assert_has(css("main > div > span", text: "Main [LiveView]"))
    |> assert_has(button("increment"))
    |> assert_has(button("update"))
    |> assert_has(button("send"))
  end

  feature "user can visit Side page", %{session: session} do
    session
    |> visit(@dev_app_url <> "/side")
    |> assert_has(css("main > div > span", text: "Side [LiveView]"))
  end

  feature "user can visit Nested page", %{session: session} do
    session
    |> visit(@dev_app_url <> "/nested")
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))
  end

  feature "user can visit Messages page", %{session: session} do
    session
    |> visit(@dev_app_url <> "/messages")
    |> assert_has(css("main > div > span", text: "Messages [LiveView]"))
  end

  feature "user can visit Embedded page", %{session: session} do
    session
    |> visit(@dev_app_url <> "/embedded")
    |> assert_has(css("main > div > span", count: 3))
  end

  feature "user can visit EmbeddedInController page", %{session: session} do
    session
    |> visit(@dev_app_url <> "/embedded_in_controller")
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))
  end
end
