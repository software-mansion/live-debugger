defmodule LiveDebugger.Utils.PubSubTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.MockPubSubUtils

  test "params_changed_topic/1" do
    assert "lvdbg/#PID<0.1.0>/params_changed" =
             PubSubUtils.params_changed_topic(:c.pid(0, 1, 0))
  end

  test "component_deleted_topic/0" do
    assert "lvdbg/component_deleted" =
             PubSubUtils.component_deleted_topic()
  end

  test "process_status_topic/0" do
    assert "lvdbg/process_status" = PubSubUtils.process_status_topic()
  end

  test "trace_topic/2" do
    pid = :c.pid(0, 1, 0)
    node_id = :c.pid(0, 2, 0)

    assert "#PID<0.1.0>/#PID<0.2.0>" =
             PubSubUtils.trace_topic(pid, node_id)
  end

  test "trace_topic/1" do
    pid = :c.pid(0, 1, 0)

    assert "#PID<0.1.0>/nil" =
             PubSubUtils.trace_topic(pid)
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
