defmodule DevWeb do
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebuggerDev.Layout, :app}

      import LiveDebuggerDev.Components
      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerDev.Helpers
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import LiveDebuggerDev.Components
      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerDev.Helpers
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
