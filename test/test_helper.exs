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

  Mox.defmock(LiveDebuggerRefactor.MockBus, for: LiveDebuggerRefactor.Bus)
  Application.put_env(:live_debugger, :bus, LiveDebuggerRefactor.MockBus)

  Mox.defmock(LiveDebuggerRefactor.MockAPIDbg, for: LiveDebuggerRefactor.API.System.Dbg)
  Application.put_env(:live_debugger, :api_dbg, LiveDebuggerRefactor.MockAPIDbg)

  Mox.defmock(LiveDebuggerRefactor.MockAPIModule, for: LiveDebuggerRefactor.API.System.Module)
  Application.put_env(:live_debugger, :api_module, LiveDebuggerRefactor.MockAPIModule)

  Mox.defmock(LiveDebuggerRefactor.MockAPIProcess, for: LiveDebuggerRefactor.API.System.Process)
  Application.put_env(:live_debugger, :api_process, LiveDebuggerRefactor.MockAPIProcess)

  Mox.defmock(LiveDebuggerRefactor.MockAPILiveViewDebug,
    for: LiveDebuggerRefactor.API.LiveViewDebug
  )

  Application.put_env(
    :live_debugger,
    :api_live_view_debug,
    LiveDebuggerRefactor.MockAPILiveViewDebug
  )

  Mox.defmock(LiveDebuggerRefactor.MockAPILiveViewDiscovery,
    for: LiveDebuggerRefactor.API.LiveViewDiscovery
  )

  Application.put_env(
    :live_debugger,
    :api_live_view_discovery,
    LiveDebuggerRefactor.MockAPILiveViewDiscovery
  )

  Mox.defmock(LiveDebuggerRefactor.MockAPISettingsStorage,
    for: LiveDebuggerRefactor.API.SettingsStorage
  )

  Application.put_env(
    :live_debugger,
    :api_settings_storage,
    LiveDebuggerRefactor.MockAPISettingsStorage
  )

  Mox.defmock(LiveDebuggerRefactor.MockAPITracesStorage,
    for: LiveDebuggerRefactor.API.TracesStorage
  )

  Application.put_env(
    :live_debugger,
    :api_traces_storage,
    LiveDebuggerRefactor.MockAPITracesStorage
  )

  Mox.defmock(LiveDebuggerRefactor.MockAPIStatesStorage,
    for: LiveDebuggerRefactor.API.StatesStorage
  )

  Application.put_env(
    :live_debugger,
    :api_states_storage,
    LiveDebuggerRefactor.MockAPIStatesStorage
  )

  Mox.defmock(LiveDebuggerRefactor.MockClient, for: LiveDebuggerRefactor.Client)
  Application.put_env(:live_debugger, :client, LiveDebuggerRefactor.MockClient)
end

ExUnit.start()
