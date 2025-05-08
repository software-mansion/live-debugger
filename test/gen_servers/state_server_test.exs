defmodule LiveDebugger.GenServers.StateServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.GenServers.StateServer
  alias LiveDebugger.MockStateServer

  setup :verify_on_exit!

  test "start_link/1" do
    assert {:ok, _pid} = StateServer.start_link()
    GenServer.stop(StateServer)
  end

  test "init/1" do
    assert {:ok, []} = StateServer.init([])
  end

  test "record_id/1" do
    pid = self()
    assert StateServer.record_id(pid) == "#{inspect(pid)}"
  end

  describe "handle_info/2" do
    test "handles new trace and updates state" do
      MockStateServer
    end
  end
end
