if Application.get_env(:live_debugger, :e2e?, false) do
  LiveDebuggerDev.Runner.run()

  {:ok, _} = Application.ensure_all_started([:wallaby, :live_debugger])

  Application.put_env(:wallaby, :base_url, LiveDebugger.App.Web.Endpoint.url())
  Application.put_env(:live_debugger, :dev_app_url, LiveDebuggerDev.Endpoint.url())

  Mox.defmock(LiveDebugger.MockIframeCheck, for: LiveDebugger.App.Web.Hooks.IframeCheck)
  Application.put_env(:live_debugger, :iframe_check, LiveDebugger.MockIframeCheck)
else
  Mox.defmock(LiveDebugger.MockBus, for: LiveDebugger.Bus)
  Application.put_env(:live_debugger, :bus, LiveDebugger.MockBus)

  Mox.defmock(LiveDebugger.MockAPIDbg, for: LiveDebugger.API.System.Dbg)
  Application.put_env(:live_debugger, :api_dbg, LiveDebugger.MockAPIDbg)

  Mox.defmock(LiveDebugger.MockAPIModule, for: LiveDebugger.API.System.Module)
  Application.put_env(:live_debugger, :api_module, LiveDebugger.MockAPIModule)

  Mox.defmock(LiveDebugger.MockAPIProcess, for: LiveDebugger.API.System.Process)
  Application.put_env(:live_debugger, :api_process, LiveDebugger.MockAPIProcess)

  Mox.defmock(LiveDebugger.MockAPILiveViewDebug,
    for: LiveDebugger.API.LiveViewDebug
  )

  Application.put_env(
    :live_debugger,
    :api_live_view_debug,
    LiveDebugger.MockAPILiveViewDebug
  )

  Mox.defmock(LiveDebugger.MockAPILiveViewDiscovery,
    for: LiveDebugger.API.LiveViewDiscovery
  )

  Application.put_env(
    :live_debugger,
    :api_live_view_discovery,
    LiveDebugger.MockAPILiveViewDiscovery
  )

  Mox.defmock(LiveDebugger.MockAPISettingsStorage,
    for: LiveDebugger.API.SettingsStorage
  )

  Application.put_env(
    :live_debugger,
    :api_settings_storage,
    LiveDebugger.MockAPISettingsStorage
  )

  Mox.defmock(LiveDebugger.MockAPITracesStorage,
    for: LiveDebugger.API.TracesStorage
  )

  Application.put_env(
    :live_debugger,
    :api_traces_storage,
    LiveDebugger.MockAPITracesStorage
  )

  Mox.defmock(LiveDebugger.MockAPIStatesStorage,
    for: LiveDebugger.API.StatesStorage
  )

  Application.put_env(
    :live_debugger,
    :api_states_storage,
    LiveDebugger.MockAPIStatesStorage
  )

  Mox.defmock(LiveDebugger.MockClient, for: LiveDebugger.Client)
  Application.put_env(:live_debugger, :client, LiveDebugger.MockClient)
end

ExUnit.start()
