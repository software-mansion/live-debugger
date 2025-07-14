defmodule LiveDebuggerRefactor.BusTest do
  @moduledoc false

  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.Bus.Impl, as: BusImpl

  defmodule TestEvents do
    use LiveDebuggerRefactor.Event

    defevent(TestEvent, name: String.t())
  end

  setup do
    start_supervised({Phoenix.PubSub, name: LiveDebuggerRefactor.Bus.PubSub})
    :ok
  end

  describe "append_bus_tree/1" do
    test "appends bus to the children" do
      assert BusImpl.append_bus_tree([]) == [
               %{
                 id: LiveDebuggerRefactor.Bus.PubSub,
                 start:
                   {Phoenix.PubSub.Supervisor, :start_link,
                    [[name: LiveDebuggerRefactor.Bus.PubSub]]},
                 type: :supervisor
               }
             ]
    end
  end

  describe "general topic" do
    test "with no specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_events() == :ok
      assert BusImpl.receive_events(self()) == :ok

      assert BusImpl.broadcast_event!(%TestEvents.TestEvent{name: "test"}) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      refute_received %TestEvents.TestEvent{name: "test"}
    end

    test "with specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_events() == :ok
      assert BusImpl.receive_events(self()) == :ok

      assert BusImpl.broadcast_event!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end

    test "ignores messages from other topics" do
      assert BusImpl.receive_events() == :ok
      assert BusImpl.receive_events(self()) == :ok

      assert BusImpl.broadcast_state!(%TestEvents.TestEvent{name: "test"}) == :ok
      assert BusImpl.broadcast_trace!(%TestEvents.TestEvent{name: "test"}) == :ok

      refute_receive %TestEvents.TestEvent{name: "test"}
      refute_receive %TestEvents.TestEvent{name: "test"}
    end
  end

  describe "states topic" do
    test "with no specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_states() == :ok
      assert BusImpl.receive_states(self()) == :ok

      assert BusImpl.broadcast_state!(%TestEvents.TestEvent{name: "test"}) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      refute_receive %TestEvents.TestEvent{name: "test"}
    end

    test "with specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_states() == :ok
      assert BusImpl.receive_states(self()) == :ok

      assert BusImpl.broadcast_state!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end

    test "ignores messages from other topics" do
      assert BusImpl.receive_states() == :ok
      assert BusImpl.receive_states(self()) == :ok

      assert BusImpl.broadcast_event!(%TestEvents.TestEvent{name: "test"}) == :ok
      assert BusImpl.broadcast_trace!(%TestEvents.TestEvent{name: "test"}) == :ok

      refute_receive %TestEvents.TestEvent{name: "test"}
      refute_receive %TestEvents.TestEvent{name: "test"}
    end
  end

  describe "traces topic" do
    test "with no specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_traces() == :ok
      assert BusImpl.receive_traces(self()) == :ok

      assert BusImpl.broadcast_trace!(%TestEvents.TestEvent{name: "test"}) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      refute_receive %TestEvents.TestEvent{name: "test"}
    end

    test "with specific pid, broadcasts event and sends them to receivers" do
      assert BusImpl.receive_traces() == :ok
      assert BusImpl.receive_traces(self()) == :ok

      assert BusImpl.broadcast_trace!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end

    test "ignores messages from other topics" do
      assert BusImpl.receive_traces() == :ok
      assert BusImpl.receive_traces(self()) == :ok

      assert BusImpl.broadcast_event!(%TestEvents.TestEvent{name: "test"}) == :ok
      assert BusImpl.broadcast_state!(%TestEvents.TestEvent{name: "test"}) == :ok

      refute_receive %TestEvents.TestEvent{name: "test"}
      refute_receive %TestEvents.TestEvent{name: "test"}
    end
  end

  describe "bang receive functions" do
    test "receive_events! returns :ok on success" do
      assert BusImpl.receive_events!() == :ok
    end

    test "receive_events! with pid returns :ok on success" do
      assert BusImpl.receive_events!(self()) == :ok
    end

    test "receive_traces! returns :ok on success" do
      assert BusImpl.receive_traces!() == :ok
    end

    test "receive_traces! with pid returns :ok on success" do
      assert BusImpl.receive_traces!(self()) == :ok
    end

    test "receive_states! returns :ok on success" do
      assert BusImpl.receive_states!() == :ok
    end

    test "receive_states! with pid returns :ok on success" do
      assert BusImpl.receive_states!(self()) == :ok
    end

    test "bang functions work with broadcasting and receiving" do
      assert BusImpl.receive_events!() == :ok
      assert BusImpl.receive_events!(self()) == :ok

      assert BusImpl.broadcast_event!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end

    test "bang functions work with traces broadcasting and receiving" do
      assert BusImpl.receive_traces!() == :ok
      assert BusImpl.receive_traces!(self()) == :ok

      assert BusImpl.broadcast_trace!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end

    test "bang functions work with states broadcasting and receiving" do
      assert BusImpl.receive_states!() == :ok
      assert BusImpl.receive_states!(self()) == :ok

      assert BusImpl.broadcast_state!(%TestEvents.TestEvent{name: "test"}, self()) == :ok

      assert_receive %TestEvents.TestEvent{name: "test"}
      assert_receive %TestEvents.TestEvent{name: "test"}
    end
  end
end
