Mox.defmock(LiveDebugger.MockLiveViewScrapper, for: LiveDebugger.Services.LiveViewScrapper)
Application.put_env(:live_debugger, :live_view_api, LiveDebugger.MockLiveViewScrapper)
ExUnit.start()
