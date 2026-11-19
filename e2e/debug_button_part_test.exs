defmodule LiveDebugger.E2E.DebugButtonPartTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  test "debug button position can be customized via ::part(debug-button)", %{page: page} do
    Page.goto!(page, "/")

    button = Page.locator(page, "#live-debugger-debug-button")

    Expect.to_have_css!(button, "bottom", "20px")
    Expect.to_have_css!(button, "right", "20px")

    # Page CSS targeting the shadow part overrides the default position
    Page.add_style_tag!(page,
      content: """
        #live-debugger::part(debug-button) {
          bottom: auto;
          right: auto;
          top: 16px;
          left: 16px;
        }
      """
    )

    Expect.to_have_css!(button, "top", "16px")
    Expect.to_have_css!(button, "left", "16px")

    Locator.click!(button)
    Page.locator(page, "#live-debugger-debug-tooltip-move-button") |> Locator.click!()
    Mouse.move!(Page.mouse(page), 300, 200)
    Locator.click!(button)

    Expect.to_have_css!(button, "top", "180px")
    Expect.to_have_css!(button, "left", "280px")

    Page.set_viewport_size!(page, %{width: 250, height: 150})

    Expect.to_have_css!(button, "top", "16px")
    Expect.to_have_css!(button, "left", "16px")
  end
end
