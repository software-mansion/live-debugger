if Application.get_env(:live_debugger, :e2e?, false) do
  LiveDebuggerDev.Runner.run()

  {:ok, _} = Application.ensure_all_started([:wallaby, :live_debugger])

  Application.put_env(:wallaby, :base_url, LiveDebuggerWeb.Endpoint.url())
  Application.put_env(:live_debugger, :dev_app_url, LiveDebuggerDev.Endpoint.url())

  Mox.defmock(LiveDebugger.MockIframeCheck, for: LiveDebuggerWeb.Hooks.IframeCheck)
  Application.put_env(:live_debugger, :iframe_check, LiveDebugger.MockIframeCheck)
else
  Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
  Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)

  Mox.defmock(LiveDebugger.MockProcessService, for: LiveDebugger.Services.System.ProcessService)
  Application.put_env(:live_debugger, :process_service, LiveDebugger.MockProcessService)

  Mox.defmock(LiveDebugger.MockPubSubUtils, for: LiveDebugger.Utils.PubSub)
  Application.put_env(:live_debugger, :pubsub_utils, LiveDebugger.MockPubSubUtils)

  Mox.defmock(LiveDebugger.MockEtsTableServer, for: LiveDebugger.GenServers.EtsTableServer)
  Application.put_env(:live_debugger, :ets_table_server, LiveDebugger.MockEtsTableServer)

  Mox.defmock(LiveDebugger.MockDbg, for: LiveDebugger.Services.System.DbgService)
  Application.put_env(:live_debugger, :dbg_service, LiveDebugger.MockDbg)

  Mox.defmock(LiveDebugger.MockStateServer, for: LiveDebugger.GenServers.StateServer)
  Application.put_env(:live_debugger, :state_server, LiveDebugger.MockStateServer)

  Mox.defmock(LiveDebugger.MockLiveViewDebugService,
    for: LiveDebugger.Services.LiveViewDebugService
  )

  Application.put_env(:live_debugger, :liveview_service, LiveDebugger.MockLiveViewDebugService)

  Mox.defmock(LiveDebugger.MockSettingsServer, for: LiveDebugger.GenServers.SettingsServer)
  Application.put_env(:live_debugger, :settings_server, LiveDebugger.MockSettingsServer)

  Mox.defmock(LiveDebuggerRefactor.MockAPIModule, for: LiveDebuggerRefactor.API.System.Module)
  Application.put_env(:live_debugger, :api_module, LiveDebuggerRefactor.MockAPIModule)

  Mox.defmock(LiveDebuggerRefactor.MockAPIProcess, for: LiveDebuggerRefactor.API.System.Process)
  Application.put_env(:live_debugger, :api_process, LiveDebuggerRefactor.MockAPIProcess)
end

ExUnit.start()
