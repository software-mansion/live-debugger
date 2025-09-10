defmodule LiveDebugger.Test.E2e.ThemeSwitchTest do
  use LiveDebugger.E2ECase

  feature "theme toggles correctly across tabs", %{session: debugger} do
    handle =
      debugger
      |> visit("/")
      |> window_handle()

    debugger
    |> visit("/settings")
    |> assert_has(dark_mode_button())
    |> click(dark_mode_button())
    |> assert_has(css("html.dark"))

    debugger
    |> focus_window(handle)
    |> assert_has(css("html.dark"))

    debugger
    |> visit("/settings")
    |> assert_has(light_mode_button())
    |> click(light_mode_button())
    |> refute_has(css("html.dark"))

    debugger
    |> focus_window(handle)
    |> refute_has(css("html.dark"))
  end

  defp light_mode_button() do
    css("#light-mode-switch")
  end

  defp dark_mode_button() do
    css("#dark-mode-switch")
  end
end
