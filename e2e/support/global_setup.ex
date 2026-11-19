defmodule LiveDebugger.E2E.GlobalSetup do
  @moduledoc """
  Starts the dev app in this VM, then warms it up.

  Warm-up that verifies the tracing infrastructure is fully initialized.

  TracingManager.handle_continue(:setup_tracing) runs asynchronously after app boot.
  We open a dev app + debugger pair and check if traces were captured.
  If not, we trigger callback in dev app and check for traces with timeout (repeated 5 times).
  """

  alias Playwright.Browser
  alias Playwright.BrowserType
  alias Playwright.Locator
  alias Playwright.Page

  @base_url "http://localhost:4005/"

  # Start the dev app in this VM (what `iex -S mix` does through `.iex.exs`) and wait for its url.
  def web_server do
    Application.put_env(:live_debugger, :e2e?, true)
    # as the `webServer` of the JS suite: `env -u TERM_PROGRAM -u EDITOR -u ELIXIR_EDITOR`
    Enum.each(~w(TERM_PROGRAM EDITOR ELIXIR_EDITOR), &System.delete_env/1)
    LiveDebuggerDev.Runner.run()
    wait_for_url(@base_url, ~s|e2e="true"|, 60_000)
  end

  def run do
    {:ok, _} = Playwright.Supervisor.start_link(name: __MODULE__.Driver)
    playwright = Playwright.instance(__MODULE__.Driver)
    browser = playwright |> Playwright.chromium() |> BrowserType.launch!()
    page = Browser.new_page!(browser)

    Page.goto!(page, @base_url)

    Page.locator(page, "#live-debugger-debug-button") |> Locator.click!()

    dbg_app =
      Page.expect_popup!(page, fn ->
        Page.get_by_text(page, "Open in new tab") |> Locator.click!()
      end)

    warm_up(page, dbg_app, 5)

    Browser.close!(browser)
    Supervisor.stop(__MODULE__.Driver)
  end

  defp warm_up(_page, _dbg_app, 0), do: :ok

  defp warm_up(page, dbg_app, attempts) do
    case Locator.wait_for(Page.locator(dbg_app, "#traces-list-stream details"), timeout: 2000) do
      :ok ->
        :ok

      {:error, _} ->
        Page.locator(page, "#increment-button") |> Locator.click!()
        warm_up(page, dbg_app, attempts - 1)
    end
  end

  defp wait_for_url(url, marker, timeout) do
    {:ok, _} = Application.ensure_all_started(:inets)
    deadline = System.monotonic_time(:millisecond) + timeout
    do_wait(String.to_charlist(url), marker, deadline)
  end

  defp do_wait(url, marker, deadline) do
    case :httpc.request(:get, {url, []}, [], body_format: :binary) do
      {:ok, {{_, 200, _}, _, body}} ->
        if String.contains?(body, marker), do: :ok, else: retry(url, marker, deadline)

      _ ->
        retry(url, marker, deadline)
    end
  end

  defp retry(url, marker, deadline) do
    if System.monotonic_time(:millisecond) > deadline, do: raise("dev app not ready: #{url}")
    Process.sleep(200)
    do_wait(url, marker, deadline)
  end
end
