defmodule LiveDebuggerWeb do
  def live_view do
    quote do
      use Phoenix.LiveView

      import Phoenix.HTML

      unquote(petal_components())
      unquote(helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML

      unquote(petal_components())
      unquote(helpers())
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

  defp helpers do
    quote do
      def ok(socket), do: {:ok, socket}
      def noreply(socket), do: {:noreply, socket}
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
