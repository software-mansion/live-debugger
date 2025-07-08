defmodule LiveDebuggerRefactor.API.System.ModuleImplTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.API.System.Module.Impl, as: ModuleImpl

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
end
