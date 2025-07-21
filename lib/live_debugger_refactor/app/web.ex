defmodule LiveDebuggerRefactor.App.Web do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {unquote(__MODULE__).Layout, :app}

      on_mount({unquote(__MODULE__).Hooks.Flash, :add_hook})

      import Phoenix.HTML
      import LiveDebuggerRefactor.Helpers
      import unquote(__MODULE__).Components
      import unquote(__MODULE__).Hooks.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebuggerRefactor.Helpers
      import unquote(__MODULE__).Components
      import unquote(__MODULE__).Hooks.Flash, only: [push_flash: 2, push_flash: 3]
    end
  end

  def component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerRefactor.Helpers
      import unquote(__MODULE__).Components
    end
  end

  def hook do
    quote do
      import Phoenix.LiveView
      import Phoenix.Component
      import LiveDebuggerRefactor.Helpers
    end
  end

  def hook_component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebuggerRefactor.Helpers
      import unquote(__MODULE__).Components
      import Phoenix.LiveView
      import Phoenix.Component
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
