defmodule LiveDebugger.App.Web do
  @moduledoc false

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {unquote(__MODULE__).Layout, :app}

      on_mount({unquote(__MODULE__).Hooks.Flash, :add_hook})
      on_mount({unquote(__MODULE__).Hooks.URL, :add_hook})
      on_mount({unquote(__MODULE__).Hooks.IframeCheck, :add_hook})

      import Phoenix.HTML
      import LiveDebugger.Helpers
      import unquote(__MODULE__).Components
      import unquote(__MODULE__).Hooks.Flash, only: [push_flash: 3, push_flash: 4]
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      import Phoenix.HTML
      import LiveDebugger.Helpers
      import unquote(__MODULE__).Components
      import unquote(__MODULE__).Hooks.Flash, only: [push_flash: 3, push_flash: 4]
    end
  end

  def component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebugger.Helpers
      import unquote(__MODULE__).Components
    end
  end

  def hook do
    quote do
      import Phoenix.LiveView
      import Phoenix.Component
      import LiveDebugger.Helpers
      import unquote(__MODULE__).Helpers.Hooks
    end
  end

  def hook_component do
    quote do
      use Phoenix.Component

      import Phoenix.HTML
      import LiveDebugger.Helpers
      import unquote(__MODULE__).Components
      import Phoenix.LiveView
      import Phoenix.Component
      import unquote(__MODULE__).Helpers.Hooks

      @behaviour unquote(__MODULE__).HookComponent
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end

  defmodule HookComponent do
    @moduledoc """
    Behaviour for components which register hooks.
    """

    @callback init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
    @callback render(assigns :: map()) :: Phoenix.LiveView.Rendered.t()
  end
end
