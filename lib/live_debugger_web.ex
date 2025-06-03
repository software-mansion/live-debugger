defmodule LiveDebuggerWeb do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {LiveDebuggerWeb.Layout, :app}

      on_mount({LiveDebuggerWeb.Hooks.Flash, :add_hook})
      on_mount({LiveDebuggerWeb.Hooks.IframeCheck, :add_hook})
      on_mount({LiveDebuggerWeb.Hooks.URL, :add_hook})

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerWeb.Components
      import LiveDebuggerWeb.Hooks.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerWeb.Components
      import LiveDebuggerWeb.Hooks.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

  def component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerWeb.Components
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule LiveDebuggerWeb.Helpers do
  @moduledoc false

  def check_assigns!(%Phoenix.LiveView.Socket{assigns: assigns} = socket, key) do
    check_assign!(assigns, key)

    socket
  end

  def check_assign!(assigns, key) do
    if Map.has_key?(assigns, key) do
      assigns
    else
      raise "Assign #{key} not found in assigns"
    end
  end

  def check_streams!(%Phoenix.LiveView.Socket{assigns: assigns} = socket, key) do
    check_stream!(assigns, key)

    socket
  end

  def check_stream!(assigns, key) do
    if Map.has_key?(assigns.streams, key) do
      assigns
    else
      raise "Stream #{key} not found in assigns.streams"
    end
  end

  def empty_map(_), do: %{}

  def ok(socket), do: {:ok, socket}

  def noreply(socket), do: {:noreply, socket}

  def cont(socket), do: {:cont, socket}

  def halt(socket), do: {:halt, socket}
end
