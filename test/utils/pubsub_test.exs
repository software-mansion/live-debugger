defmodule LiveDebugger.Utils.PubSubTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.MockPubSubUtils

  test "node_changed_topic/1" do
    assert "lvdbg/phx-GBsi_6M7paYhySQj/node_changed" =
             PubSubUtils.node_changed_topic("phx-GBsi_6M7paYhySQj")
  end

  test "component_deleted_topic/1" do
    trace = %Trace{socket_id: "phx-GBsi_6M7paYhySQj", transport_pid: :c.pid(0, 1, 0)}

    assert "lvdbg/#PID<0.1.0>/phx-GBsi_6M7paYhySQj/component_deleted" =
             PubSubUtils.component_deleted_topic(trace)
  end

  test "component_deleted_topic/2" do
    socket_id = "phx-GBsi_6M7paYhySQj"
    transport_pid = :c.pid(0, 1, 0)

    assert "lvdbg/#PID<0.1.0>/phx-GBsi_6M7paYhySQj/component_deleted" =
             PubSubUtils.component_deleted_topic(socket_id, transport_pid)
  end

  test "process_status_topic/1" do
    pid = :c.pid(0, 1, 0)
    assert "lvdbg/#PID<0.1.0>/process_status" = PubSubUtils.process_status_topic(pid)
  end

  test "process_status_topic/0" do
    assert "lvdbg/*/process_status" = PubSubUtils.process_status_topic()
  end

  test "tsnf_topic/4" do
    socket_id = "phx-GBsi_6M7paYhySQj"
    transport_pid = :c.pid(0, 1, 0)
    node_id = :c.pid(0, 2, 0)
    fun = :handle_info

    assert "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info/:call" =
             PubSubUtils.tsnf_topic(socket_id, transport_pid, node_id, fun)

    assert "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info/:call" =
             PubSubUtils.tsnf_topic(socket_id, transport_pid, node_id, fun, :call)

    assert "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info/:return" =
             PubSubUtils.tsnf_topic(socket_id, transport_pid, node_id, fun, :return)
  end

  test "ts_f_topic/3" do
    socket_id = "phx-GBsi_6M7paYhySQj"
    transport_pid = :c.pid(0, 1, 0)
    fun = :handle_info

    assert "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/*/:handle_info" =
             PubSubUtils.ts_f_topic(socket_id, transport_pid, fun)
  end

  describe "mock" do
    test "broadcast/2" do
      topic = "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info"
      payload = %{key: "value"}

      MockPubSubUtils
      |> expect(:broadcast, fn ^topic, ^payload -> :ok end)

      assert :ok = PubSubUtils.broadcast(topic, payload)
    end

    test "subscribe!/1" do
      topic = "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info"
      topics = [topic, topic]

      MockPubSubUtils
      |> expect(:subscribe!, fn ^topic -> :ok end)
      |> expect(:subscribe!, fn ^topics -> :ok end)

      assert :ok = PubSubUtils.subscribe!(topic)
      assert :ok = PubSubUtils.subscribe!(topics)
    end

    test "unsubscribe!/1" do
      topic = "#PID<0.1.0>/phx-GBsi_6M7paYhySQj/#PID<0.2.0>/:handle_info"
      topics = [topic, topic]

      MockPubSubUtils
      |> expect(:unsubscribe, fn ^topic -> :ok end)
      |> expect(:unsubscribe, fn ^topics -> :ok end)

      assert :ok = PubSubUtils.unsubscribe(topic)
      assert :ok = PubSubUtils.unsubscribe(topics)
    end
  end
end
