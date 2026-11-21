defmodule LiveDebugger.E2E.Case do
  @moduledoc """
  Runs every module on Desktop Chrome and Desktop Firefox (`PW_BROWSER=firefox` runs one), and
  sets up the dev app and debugger pair.

  A module with `@moduletag dev_url: "/"` gets `dev_app` (the page, on that URL), and with
  `@moduletag :dbg_app` also `dbg_app` (the debugger, opened from the dev app's debug button).
  """
  use ExUnit.CaseTemplate

  alias Playwright.Page

  @projects [chromium: "Desktop Chrome", firefox: "Desktop Firefox"]

  @doc """
  The config's `projects`: all of them, or `PW_BROWSER`'s (`chromium` or `firefox`). The serial
  specs' are named with the `"serial-tests"` prefix, as there.
  """
  def projects(prefix \\ nil) do
    name = System.get_env("PW_BROWSER", "")

    projects =
      for {project, device} <- @projects, name in ["", "#{project}"], do: {project, device}

    if projects == [] do
      available = Enum.map_join(@projects, ", ", fn {project, _} -> ~s("#{project}") end)
      raise ArgumentError, ~s[Project(s) "#{name}" not found. Available projects: #{available}]
    end

    for {project, device} <- projects do
      title = Enum.join(List.wrap(prefix) ++ ["#{project}"], " ")
      Playwright.Test.parameters([name: title] ++ Playwright.device(device))
    end
  end

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
