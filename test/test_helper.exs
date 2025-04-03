Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
Mox.defmock(LiveDebugger.MockProcessService, for: LiveDebugger.Services.System.ProcessService)

ExUnit.start()

LiveDebuggerDev.Runner.run()

{:ok, _} = Application.ensure_all_started([:wallaby, :live_debugger])

Application.put_env(:wallaby, :base_url, LiveDebugger.Endpoint.url())
