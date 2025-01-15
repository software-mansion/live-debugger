defmodule LiveDebugger.Router do
  @moduledoc """
  Inspiration was taken from Phoenix LiveDashboard
  https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/router.ex
  """

  defmacro live_debugger(path, opts \\ []) do
    quote bind_quoted: binding() do
      pipeline :dbg_browser do
        plug(:accepts, ["html"])
        plug(:fetch_session)
        plug(:fetch_live_flash)
        plug(:put_root_layout, html: {LiveDebugger.Layout, :root})
        plug(:protect_from_forgery)
        plug(:put_secure_browser_headers)
      end

      scope path do
        pipe_through([:dbg_browser])

        import Phoenix.Router
        import Phoenix.LiveView.Router

        get("/css-:md5", LiveDebugger.Controllers.Assets, :css)
        get("/js-:md5", LiveDebugger.Controllers.Assets, :js)

        live("/", LiveDebugger.LiveViews.HomeLive)
        live("/:socket_id", LiveDebugger.LiveViews.ChannelDashboard)
        live("/:socket_id/:node_id", LiveDebugger.LiveViews.ChannelDashboard)
      end

      def live_debugger_prefix(), do: unquote(path)
    end
  end
end
