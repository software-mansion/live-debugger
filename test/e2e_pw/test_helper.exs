# The Playwright suite. Run with `mix e2e`: starts the dev app in this VM and warms it up first.
# The suite crashes LiveViews on purpose; keep the app's crash logs out of the test output.
Logger.configure(level: :emergency)

Code.require_file("support/utils.ex", __DIR__)
Code.require_file("support/case.ex", __DIR__)
Code.require_file("support/global_setup.ex", __DIR__)

LiveDebugger.E2E.GlobalSetup.web_server()
LiveDebugger.E2E.GlobalSetup.run()

ExUnit.start(timeout: 30_000)
