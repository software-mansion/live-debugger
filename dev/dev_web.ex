defmodule DevWeb do
  @moduledoc false
  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebuggerDev.Layout, :app}

      import DevWeb.Helpers
      import LiveDebuggerDev.Components
      import LiveDebuggerDev.Helpers
      import Phoenix.HTML
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import DevWeb.Helpers
      import LiveDebuggerDev.Components
      import LiveDebuggerDev.Helpers
      import Phoenix.HTML
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmodule Helpers do
    @moduledoc false
    def ok(socket), do: {:ok, socket}
    def noreply(socket), do: {:noreply, socket}
  end
end
