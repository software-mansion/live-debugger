defmodule LiveDebuggerWeb do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebugger.Layout, :app}

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebugger.Components
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebugger.Components
    end
  end

  @spec component() :: {:__block__, [], [{:import, [...], [...]} | {:use, [...], [...]}, ...]}
  def component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebugger.Components
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule LiveDebuggerWeb.Helpers do
  @moduledoc false

  def empty_map(_), do: %{}

  def ok(socket), do: {:ok, socket}
  def noreply(socket), do: {:noreply, socket}
end
