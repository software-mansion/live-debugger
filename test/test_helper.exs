Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)

Mox.defmock(LiveDebugger.MockProcessService, for: LiveDebugger.Services.System.ProcessService)
Application.put_env(:live_debugger, :process_service, LiveDebugger.MockProcessService)

ExUnit.start()
