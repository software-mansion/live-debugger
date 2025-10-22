defmodule LiveDebugger.Services.CallbackTracer.Actions.DiffTraceTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Services.CallbackTracer.Actions.DiffTrace
  alias LiveDebugger.Structs.DiffTrace, as: DiffTraceStruct
  alias LiveDebugger.Services.CallbackTracer.Events.DiffTraceCreated
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockBus
  alias LiveDebugger.Fakes
  import Mox

  setup :verify_on_exit!

  describe "maybe_create_diff/4" do
    test "creates a diff trace successfully" do
      n = -1
      pid = :c.pid(0, 1, 0)
      timestamp = {1000, 100, 1000}
      iodata = Jason.encode!([1, 2, 3, "diff", %{some: "diff content"}])

      assert {:ok, result} = DiffTrace.maybe_create_diff(n, pid, timestamp, iodata)

      assert %DiffTraceStruct{id: ^n, pid: ^pid, body: %{"some" => "diff content"}, size: 23} =
               result
    end

    test "returns error when JSON is invalid" do
      n = -4
      pid = :c.pid(0, 4, 0)
      timestamp = {1000, 400, 1000}
      invalid_iodata = "invalid json"

      result = DiffTrace.maybe_create_diff(n, pid, timestamp, invalid_iodata)

      assert {:error, %Jason.DecodeError{}} = result
    end
  end

  describe "persist_trace/1" do
    test "persists diff trace successfully" do
      pid = :c.pid(0, 1, 0)
      diff_trace = Fakes.diff_trace(id: -1, pid: pid)
      table_ref = make_ref()

      MockAPITracesStorage
      |> expect(:get_table, fn ^pid -> table_ref end)
      |> expect(:insert!, fn ^table_ref, ^diff_trace -> true end)

      result = DiffTrace.persist_trace(diff_trace)

      assert {:ok, ^table_ref} = result
    end

    test "returns error when get_table returns nil" do
      pid = :c.pid(0, 2, 0)
      diff_trace = Fakes.diff_trace(id: -2, pid: pid)

      MockAPITracesStorage
      |> expect(:get_table, fn ^pid -> nil end)

      result = DiffTrace.persist_trace(diff_trace)

      assert {:error, "Could not persist trace"} = result
    end

    test "returns error when insert! fails" do
      pid = :c.pid(0, 3, 0)
      diff_trace = Fakes.diff_trace(id: -3, pid: pid)
      table_ref = make_ref()

      MockAPITracesStorage
      |> expect(:get_table, fn ^pid -> table_ref end)
      |> expect(:insert!, fn ^table_ref, ^diff_trace -> false end)

      result = DiffTrace.persist_trace(diff_trace)

      assert {:error, "Could not persist trace"} = result
    end
  end

  describe "publish_diff/2" do
    test "publishes diff trace successfully" do
      pid = :c.pid(0, 1, 0)
      diff_trace = Fakes.diff_trace(id: -1, pid: pid)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn diff, ^pid ->
        assert %DiffTraceCreated{trace_id: -1, ets_ref: ^table_ref, pid: ^pid} = diff

        :ok
      end)

      result = DiffTrace.publish_diff(diff_trace, table_ref)

      assert :ok = result
    end

    test "returns error when broadcast fails" do
      pid = :c.pid(0, 3, 0)
      diff_trace = Fakes.diff_trace(id: -3, pid: pid)
      table_ref = make_ref()

      MockBus
      |> expect(:broadcast_trace!, fn %DiffTraceCreated{}, ^pid ->
        raise %RuntimeError{message: "Broadcast failed"}
      end)

      result = DiffTrace.publish_diff(diff_trace, table_ref)

      assert {:error, %RuntimeError{message: "Broadcast failed"}} = result
    end
  end
end
