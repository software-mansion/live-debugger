defmodule LiveDebugger.GenServers.StateServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Fakes
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.GenServers.StateServer
  alias LiveDebugger.MockPubSubUtils
  alias LiveDebugger.MockProcessService

  setup :verify_on_exit!

  test "init/1" do
    node_rendered_topic = PubSubUtils.node_rendered()
    process_status_topic = PubSubUtils.process_status_topic(nil)

    MockPubSubUtils
    |> expect(:subscribe!, fn ^node_rendered_topic -> :ok end)
    |> expect(:subscribe!, fn ^process_status_topic -> :ok end)

    assert {:ok, []} = StateServer.init([])

    assert Enum.find(:ets.all(), false, &(&1 == StateServer.ets_table_name()))
  end

  test "record_id/1" do
    pid = self()
    assert StateServer.record_id(pid) == "#{inspect(pid)}"
  end

  describe "handle_info/2" do
    test "handles render trace and updates state" do
      pid = :c.pid(0, 1, 0)
      transport_pid = :c.pid(0, 7, 0)
      socket_id = "socket_id"
      :ets.new(StateServer.ets_table_name(), [:named_table, :public, :ordered_set])
      :ets.insert(StateServer.ets_table_name(), {inspect(pid), :old_state})

      trace =
        Fakes.trace(
          function: :render,
          pid: pid,
          transport_pid: transport_pid,
          socket_id: socket_id
        )

      state_changed_node_topic = PubSubUtils.state_changed_topic(socket_id, transport_pid, pid)
      state_changed_topic = PubSubUtils.state_changed_topic(socket_id, transport_pid, nil)

      state = Fakes.state()

      MockProcessService
      |> expect(:state, fn ^pid -> {:ok, state} end)

      MockPubSubUtils
      |> expect(:broadcast, fn ^state_changed_node_topic, {:state_changed, ^state} -> :ok end)
      |> expect(:broadcast, fn ^state_changed_topic, {:state_changed, ^state} -> :ok end)

      StateServer.handle_info({:render_trace, trace}, [])

      assert [{_, ^state}] = :ets.lookup(StateServer.ets_table_name(), inspect(pid))
    end

    test "handles dead process status and deletes table record" do
      pid = :c.pid(0, 1, 0)
      :ets.new(StateServer.ets_table_name(), [:named_table, :public, :ordered_set])
      :ets.insert(StateServer.ets_table_name(), {inspect(pid), :old_state})

      StateServer.handle_info({:process_status, {:dead, pid}}, [])

      assert [] = :ets.lookup(StateServer.ets_table_name(), inspect(pid))
    end
  end
end
