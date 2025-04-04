defmodule LiveDebuggerWeb do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebugger.Layout, :app}

      on_mount({LiveDebugger.Flash, :add_hook})

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebugger.Components
      import LiveDebugger.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebugger.Components
      import LiveDebugger.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

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
