defmodule LiveDebugger.Services.ModuleDiscoveryServiceTest do
  use ExUnit.Case, async: true

  import Mox
  import LiveDebugger.Test.Mocks

  alias LiveDebugger.Services.ModuleDiscoveryService

  setup :set_mocks

  describe "live_view_modules/1" do
    test "filters LiveView modules correctly" do
      modules = [
        CoolApp.LiveViews.UserDashboard,
        CoolApp.Service.UserService,
        CoolApp.LiveComponent.UserElement
      ]

      LiveDebugger.MockModuleService
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

      LiveDebugger.MockModuleService
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

      LiveDebugger.MockModuleService
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

      LiveDebugger.MockModuleService
      |> expect(:loaded?, 3, fn _module -> false end)

      result = ModuleDiscoveryService.live_component_modules(modules)
      assert result == []
    end
  end
end
