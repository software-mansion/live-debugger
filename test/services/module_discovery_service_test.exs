defmodule LiveDebugger.Services.ModuleDiscoveryServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.MockModuleService

  @modules [
    CoolApp.LiveViews.UserDashboard,
    CoolApp.LiveViews.UserProfile,
    CoolApp.Service.UserService,
    CoolApp.LiveComponent.UserElement,
    CoolApp.LiveComponent.UserSettings
  ]

  test "all_modules/0 returns all modules" do
    modules = @modules

    MockModuleService
    |> expect(:all, fn ->
      Enum.map(modules, fn module ->
        {to_charlist(module), to_charlist("/prefix/lib/#{module}.beam"),
         module == CoolApp.LiveViews.UserDashboard}
      end)
    end)

    assert modules == ModuleDiscoveryService.all_modules()
  end

  describe "live_view_modules/1" do
    test "filters LiveView modules correctly" do
      modules = @modules

      MockModuleService
      |> expect(:loaded?, 5, fn _module -> true end)
      |> expect(:behaviours, 5, fn module ->
        get_behaviours(module)
      end)

      assert ModuleDiscoveryService.live_view_modules(modules) == [
               CoolApp.LiveViews.UserDashboard,
               CoolApp.LiveViews.UserProfile
             ]
    end

    test "filters unloaded modules correctly" do
      modules = @modules

      MockModuleService
      |> expect(:loaded?, 5, fn
        CoolApp.LiveViews.UserDashboard -> false
        _ -> true
      end)
      |> expect(:behaviours, 4, fn module ->
        get_behaviours(module)
      end)

      assert ModuleDiscoveryService.live_view_modules(modules) == [
               CoolApp.LiveViews.UserProfile
             ]
    end
  end

  describe "live_component_modules/1" do
    test "filters LiveComponent modules correctly" do
      modules = @modules

      MockModuleService
      |> expect(:loaded?, 5, fn _module -> true end)
      |> expect(:behaviours, 5, fn module ->
        get_behaviours(module)
      end)

      assert ModuleDiscoveryService.live_component_modules(modules) == [
               CoolApp.LiveComponent.UserElement,
               CoolApp.LiveComponent.UserSettings
             ]
    end

    test "filters unloaded modules correctly" do
      modules = @modules

      MockModuleService
      |> expect(:loaded?, 5, fn
        CoolApp.LiveComponent.UserElement -> false
        _ -> true
      end)
      |> expect(:behaviours, 4, fn module ->
        get_behaviours(module)
      end)

      assert ModuleDiscoveryService.live_component_modules(modules) == [
               CoolApp.LiveComponent.UserSettings
             ]
    end
  end

  defp get_behaviours(module) do
    case module do
      CoolApp.LiveViews.UserDashboard -> [Phoenix.LiveView]
      CoolApp.LiveViews.UserProfile -> [Phoenix.LiveView]
      CoolApp.Service.UserService -> []
      CoolApp.LiveComponent.UserElement -> [Phoenix.LiveComponent]
      CoolApp.LiveComponent.UserSettings -> [Phoenix.LiveComponent]
    end
  end
end
