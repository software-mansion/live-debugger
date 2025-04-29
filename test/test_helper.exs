if Application.get_env(:live_debugger, :e2e?, false) do
  LiveDebuggerDev.Runner.run()

  {:ok, _} = Application.ensure_all_started([:wallaby, :live_debugger])

  Application.put_env(:wallaby, :base_url, LiveDebuggerWeb.Endpoint.url())
  Application.put_env(:live_debugger, :dev_app_url, LiveDebuggerDev.Endpoint.url())
else
  Mox.defmock(LiveDebugger.MockModuleService, for: LiveDebugger.Services.System.ModuleService)
  Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)

  Mox.defmock(LiveDebugger.MockProcessService, for: LiveDebugger.Services.System.ProcessService)
  Application.put_env(:live_debugger, :process_service, LiveDebugger.MockProcessService)

  Mox.defmock(LiveDebugger.MockPubSubUtils, for: LiveDebugger.Utils.PubSub)
  Application.put_env(:live_debugger, :pubsub_utils, LiveDebugger.MockPubSubUtils)

  Mox.defmock(LiveDebugger.MockEtsTableServer, for: LiveDebugger.GenServers.EtsTableServer)
  Application.put_env(:live_debugger, :ets_table_server, LiveDebugger.MockEtsTableServer)
end

ExUnit.start()
