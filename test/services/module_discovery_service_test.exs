defmodule LiveDebugger.Services.ModuleDiscoveryServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.ModuleDiscoveryService
  alias LiveDebugger.MockModuleService

  test "all_modules/0 returns all modules" do
    modules = [
      CoolApp.LiveViews.UserDashboard,
      CoolApp.Service.UserService,
      CoolApp.LiveComponent.UserElement
    ]

    MockModuleService
    |> expect(:all, fn ->
      Enum.map(modules, fn module ->
        {to_charlist(module), to_charlist("/prefix/lib/#{module}.beam"),
         module == CoolApp.LiveViews.UserDashboard}
      end)
    end)

    result = ModuleDiscoveryService.all_modules()
    assert result == modules
  end

  describe "live_view_modules/1" do
    test "filters LiveView modules correctly" do
      modules = [
        CoolApp.LiveViews.UserDashboard,
        CoolApp.Service.UserService,
        CoolApp.LiveComponent.UserElement
      ]

      MockModuleService
      |> expect(:loaded?, 3, fn _module -> true end)
      |> expect(:behaviours, 3, fn module ->
        case module do
          CoolApp.LiveViews.UserDashboard -> [Phoenix.LiveView]
          CoolApp.Service.UserService -> []
          CoolApp.LiveComponent.UserElement -> [Phoenix.LiveComponent]
        end
      end)

      result = ModuleDiscoveryService.live_view_modules(modules)
      assert result == [CoolApp.LiveViews.UserDashboard]
    end

    test "filters unloaded modules correctly" do
      modules = [
        CoolApp.LiveViews.UserDashboard,
        CoolApp.Service.UserService,
        CoolApp.LiveComponent.UserElement
      ]

      MockModuleService
      |> expect(:loaded?, 3, fn _module -> false end)

      result = ModuleDiscoveryService.live_view_modules(modules)
      assert result == []
    end
  end

  describe "live_component_modules/1" do
    test "filters LiveComponent modules correctly" do
      loaded_modules = [
        CoolApp.LiveViews.UserDashboard,
        CoolApp.Service.UserService,
        CoolApp.LiveComponent.UserElement
      ]

      MockModuleService
      |> expect(:loaded?, 3, fn _module -> true end)
      |> expect(:behaviours, 3, fn module ->
        case module do
          CoolApp.LiveViews.UserDashboard -> [Phoenix.LiveView]
          CoolApp.Service.UserService -> []
          CoolApp.LiveComponent.UserElement -> [Phoenix.LiveComponent]
        end
      end)

      result = ModuleDiscoveryService.live_component_modules(loaded_modules)
      assert result == [CoolApp.LiveComponent.UserElement]
    end

    test "filters unloaded modules correctly" do
      modules = [
        CoolApp.LiveViews.UserDashboard,
        CoolApp.Service.UserService,
        CoolApp.LiveComponent.UserElement
      ]

      MockModuleService
      |> expect(:loaded?, 3, fn _module -> false end)

      result = ModuleDiscoveryService.live_component_modules(modules)
      assert result == []
    end
  end
end
