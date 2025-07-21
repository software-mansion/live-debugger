defmodule LiveDebuggerRefactor.Services.StateManager.GenServers.StateManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.StateManager.GenServers.StateManager
  alias LiveDebuggerRefactor.MockBus

  setup :verify_on_exit!

  describe "init/1" do
    test "properly initializes StateManager" do
      expect(MockBus, :receive_traces!, fn -> :ok end)

      assert {:ok, []} = StateManager.init([])
    end
  end
end
