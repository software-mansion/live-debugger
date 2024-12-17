Mox.defmock(LiveDebugger.MockLiveViewScraper, for: LiveDebugger.Services.LiveViewScraper)
Application.put_env(:live_debugger, :live_view_api, LiveDebugger.MockLiveViewScraper)
ExUnit.start()
