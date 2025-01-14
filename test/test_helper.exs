Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)

ExUnit.start()
