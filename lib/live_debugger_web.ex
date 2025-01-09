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
        Loading
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

  @spec live_path(Phoenix.LiveView.Socket.t(), atom(), list()) :: String.t()
  def live_path(%Phoenix.LiveView.Socket{} = socket, module, args \\ []) do
    helpers_module = (Atom.to_string(socket.router) <> ".Helpers") |> String.to_atom()
    helpers_module.live_path(socket.endpoint, module, args)
  end
end
