Mox.defmock(LiveDebugger.MockLiveViewApi, for: LiveDebugger.Service.LiveViewApi)
Application.put_env(:live_debugger, :live_view_api, LiveDebugger.MockLiveViewApi)
ExUnit.start()
