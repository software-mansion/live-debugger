defmodule LiveDebuggerWeb do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebugger.Layout, :app}

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers

      unquote(petal_components())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers

      unquote(petal_components())
    end
  end

  def component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers

      unquote(petal_components())
    end
  end

  defp petal_components do
    quote do
      import PetalComponents.{
        Typography,
        Card,
        Icon,
        Container,
        Loading,
        Alert,
        Button,
        Link
      }
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule LiveDebuggerWeb.Helpers do
  @moduledoc false

  def ok(socket), do: {:ok, socket}
  def noreply(socket), do: {:noreply, socket}

  def live_debugger_base_url(socket) do
    socket.router.live_debugger_prefix()
  end
end
