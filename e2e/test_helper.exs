# The Playwright suite. Run with `mix e2e`: starts the dev app in this VM and warms it up first.
# playwright_ex logs every API call at :debug; keep the app's warnings and errors.
Logger.configure(level: :warning)

Code.require_file("support/utils.ex", __DIR__)
Code.require_file("support/case.ex", __DIR__)
Code.require_file("support/global_setup.ex", __DIR__)

LiveDebugger.E2E.GlobalSetup.web_server()
LiveDebugger.E2E.GlobalSetup.run()

ExUnit.start(timeout: 30_000)
