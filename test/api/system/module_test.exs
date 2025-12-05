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

    test "returns empty list if module does not exist" do
      assert [] = ModuleImpl.behaviours(NonExistingModule)
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

  describe "live_module?/1" do
    defmodule LiveViewModule do
      use Phoenix.LiveView
    end

    defmodule LiveComponentModule do
      use Phoenix.LiveComponent
    end

    defmodule RegularModule do
    end

    test "returns true for a LiveView module" do
      assert ModuleImpl.live_module?(LiveViewModule) == true
    end

    test "returns true for a LiveComponent module" do
      assert ModuleImpl.live_module?(LiveComponentModule) == true
    end

    test "returns false for a regular module" do
      assert ModuleImpl.live_module?(RegularModule) == false
    end

    test "returns false for a non-existing module" do
      assert ModuleImpl.live_module?(NonExistingModule) == false
    end
  end
end
