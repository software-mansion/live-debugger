defmodule LiveDebugger.API.System.ModuleImplTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.API.System.Module.Impl, as: ModuleImpl

  describe "behaviours/1" do
    defmodule TestLiveViewModule do
      use Phoenix.LiveView
    end

    defmodule TestLiveComponentModule do
      use Phoenix.LiveComponent
    end

    defmodule TestNoBehaviourModule do
    end

    test "returns correct behaviours" do
      assert Phoenix.LiveView in ModuleImpl.behaviours(TestLiveViewModule)
      assert Phoenix.LiveComponent in ModuleImpl.behaviours(TestLiveComponentModule)
      assert [] = ModuleImpl.behaviours(TestNoBehaviourModule)
    end
  end

  describe "loaded?/1" do
    defmodule TestModule do
    end

    test "returns true if module is loaded" do
      assert ModuleImpl.loaded?(TestModule) == true
    end

    test "returns false if module does not exist" do
      assert ModuleImpl.loaded?(NonExistingModule) == false
    end
  end
end
