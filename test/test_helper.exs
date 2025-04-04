unless Application.get_env(:live_debugger, :e2e, false) do
  Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
  Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)

  Mox.defmock(LiveDebugger.MockProcessService, for: LiveDebugger.Services.System.ProcessService)
  Application.put_env(:live_debugger, :process_service, LiveDebugger.MockProcessService)
end

ExUnit.start()
