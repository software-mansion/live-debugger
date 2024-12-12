Mox.defmock(LiveDebugger.MockLiveViewApi, for: LiveDebugger.Services.LiveViewApi)
Application.put_env(:live_debugger, :live_view_api, LiveDebugger.MockLiveViewApi)
ExUnit.start()
