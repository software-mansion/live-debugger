defmodule LiveDebugger.Services.ModuleDiscoveryTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Services.ModuleDiscovery

  describe "find_live_modules/0" do
    test "finds LiveViews and LiveComponents correctly" do
      Module.create(
        LiveDebuggerTest.TestView,
        live_view_contents(),
        Macro.Env.location(__ENV__)
      )

      Module.create(
        LiveDebuggerTest.TestComponent,
        live_component_contents(),
        Macro.Env.location(__ENV__)
      )

      Module.create(
        LiveDebuggerTest.OtherModule,
        other_contents(),
        Macro.Env.location(__ENV__)
      )

      assert %{
               live_views: [LiveDebuggerTest.TestView],
               live_components: [LiveDebuggerTest.TestComponent]
             } =
               ModuleDiscovery.find_live_modules()
    end
  end

  defp live_view_contents() do
    quote do
      @behaviour Phoenix.LiveView
    end
  end

  defp live_component_contents() do
    quote do
      @behaviour Phoenix.LiveComponent
    end
  end

  defp other_contents() do
    quote do
      @behaviour Other.Behaviour
    end
  end
end
