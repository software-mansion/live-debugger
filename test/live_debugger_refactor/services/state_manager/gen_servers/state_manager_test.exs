defmodule LiveDebuggerRefactor.Services.StateManager.GenServers.StateManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.StateManager.GenServers.StateManager
  alias LiveDebuggerRefactor.MockBus

  setup :verify_on_exit!

  describe "init/1" do
    test "properly initializes StateManager" do
      MockBus
      |> expect(:receive_traces!, fn -> :ok end)
      |> expect(:receive_events!, fn -> :ok end)

      assert {:ok, []} = StateManager.init([])
    end
  end
end
