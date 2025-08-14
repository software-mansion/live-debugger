if Application.get_env(:live_debugger, :e2e?, false) do
  LiveDebuggerDev.Runner.run()

  {:ok, _} = Application.ensure_all_started([:wallaby, :live_debugger])

  Application.put_env(:wallaby, :base_url, LiveDebuggerRefactor.App.Web.Endpoint.url())
  Application.put_env(:live_debugger, :dev_app_url, LiveDebuggerDev.Endpoint.url())

  Mox.defmock(LiveDebugger.MockIframeCheck, for: LiveDebuggerRefactor.App.Web.Hooks.IframeCheck)
  Application.put_env(:live_debugger, :iframe_check, LiveDebugger.MockIframeCheck)
else
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
