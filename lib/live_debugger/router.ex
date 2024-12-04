defmodule LiveDebugger.Router do
  @moduledoc """
  Main inspiration https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/router.ex
  Provides LiveView routing for LiveDebugger.
  """
  defmacro live_debugger(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path do
        import Phoenix.Router
        import Phoenix.LiveView.Router

        live("/hello", LiveDebugger.Web.HelloLive)
        live("/greet/:name", LiveDebugger.Web.GreetLive)
      end
    end
  end
end
