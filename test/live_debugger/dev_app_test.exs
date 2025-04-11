defmodule LiveDebugger.DevAppTest do
  use LiveDebugger.E2ECase

  feature "user can visit dev page", %{session: session} do
    session
    |> visit(dev_path("/"))
    |> assert_has(css("main > div > span", text: "Main [LiveView]"))
    |> assert_has(button("increment"))
    |> assert_has(button("update"))
    |> assert_has(button("send"))

    session
    |> visit(dev_path("/side"))
    |> assert_has(css("main > div > span", text: "Side [LiveView]"))

    session
    |> visit(dev_path("/nested"))
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))

    session
    |> visit(dev_path("/messages"))
    |> assert_has(css("main > div > span", text: "Messages [LiveView]"))

    session
    |> visit(dev_path("/embedded"))
    |> assert_has(css("main > div > span", count: 3))

    session
    |> visit(dev_path("/embedded_in_controller"))
    |> assert_has(css("main > div > span", text: "Nested Live Views [LiveView]"))
  end

  defp dev_path(path), do: @dev_app_url <> path
end
