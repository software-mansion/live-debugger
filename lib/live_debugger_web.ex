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

  def hook do
    quote do
      import Phoenix.LiveView
      import Phoenix.Component
      import LiveDebuggerWeb.Helpers
    end
  end

  def hook_component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerWeb.Helpers
      import LiveDebuggerWeb.Components
      import Phoenix.LiveView
      import Phoenix.Component
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end

defmodule LiveDebuggerWeb.Helpers do
  @moduledoc false

  def put_conditionally(opts, key, value) do
    if value do
      Keyword.put(opts, key, value)
    else
      opts
    end
  end

  def check_assigns!(%Phoenix.LiveView.Socket{assigns: assigns} = socket, key)
      when is_atom(key) do
    if Map.has_key?(assigns, key) do
      socket
    else
      raise "Assign #{key} not found in assigns"
    end
  end

  def check_assigns!(socket, keys) when is_list(keys) do
    Enum.each(keys, &check_assigns!(socket, &1))

    socket
  end

  def check_stream!(%Phoenix.LiveView.Socket{assigns: assigns} = socket, key) do
    if Map.has_key?(assigns.streams, key) do
      socket
    else
      raise "Stream #{key} not found in assigns.streams"
    end
  end

  def check_hook!(socket, key) do
    if Map.has_key?(socket.private, :hooks) and key in socket.private.hooks do
      socket
    else
      raise "Hook #{key} not found in socket.private.hooks"
    end
  end

  def register_hook(socket, key) do
    if Map.has_key?(socket.private, :hooks) do
      Phoenix.LiveView.put_private(socket, :hooks, [key | socket.private.hooks])
    else
      Phoenix.LiveView.put_private(socket, :hooks, [key])
    end
  end

  def empty_map(_), do: %{}

  def ok(socket), do: {:ok, socket}

  def noreply(socket), do: {:noreply, socket}

  def cont(socket), do: {:cont, socket}

  def halt(socket), do: {:halt, socket}
end
