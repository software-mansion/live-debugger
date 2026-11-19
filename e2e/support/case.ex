defmodule LiveDebugger.E2E.Case do
  @moduledoc """
  Runs every module on Desktop Chrome and Desktop Firefox, and sets up the dev app and debugger pair.

  A module with `@moduletag dev_url: "/"` gets `dev_app` (the page, on that URL), and with
  `@moduletag :dbg_app` also `dbg_app` (the debugger, opened from the dev app's debug button).
  """
  use ExUnit.CaseTemplate

  alias Playwright.Page

  def projects,
    do:
      for(
        device <- ["Desktop Chrome", "Desktop Firefox"],
        do: Playwright.Test.parameters(Playwright.device(device))
      )

  using opts do
    quote do
      use Playwright.Case, unquote(opts)

      import LiveDebugger.E2E.Utils

      setup {LiveDebugger.E2E.Case, :dev_app}
    end
  end

  @doc false
  # Opens the dev app and, with `:dbg_app`, the debugger
  def dev_app(%{page: page} = ctx) do
    case ctx do
      %{dev_url: dev_url} ->
        Page.goto!(page, dev_url)
        dev = %{dev_app: page}

        if ctx[:dbg_app],
          do: Map.put(dev, :dbg_app, LiveDebugger.E2E.Utils.open_debugger(page)),
          else: dev

      _ ->
        :ok
    end
  end
end
