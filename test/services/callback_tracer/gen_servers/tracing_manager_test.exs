defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.MockBus
  alias LiveDebugger.MockAPIDbg
  alias LiveDebugger.MockAPIFileSystem
  alias LiveDebugger.MockAPIModule
  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager

  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  setup :verify_on_exit!

  describe "init/1" do
    test "sets up the tracing manager properly" do
      expect(MockBus, :receive_events!, fn -> :ok end)
      assert {:ok, []} = TracingManager.init([])

      assert_receive :setup_tracing
    end
  end

  describe "handle_info/2" do
    test "handles :setup_tracing event" do
      MockAPIModule
      |> expect(:all, 2, fn -> [{~c"Test.LiveViewModule", ~c"/path/Module.beam", true}] end)
      |> expect(:loaded?, 2, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)
      |> expect(:live_module?, fn _ -> true end)

      MockAPIDbg
      |> expect(:tracer, fn _ -> {:ok, self()} end)
      |> expect(:process, fn _ -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      MockAPIFileSystem
      |> expect(:start_link, fn opts ->
        assert Keyword.get(opts, :name) == :lvdbg_file_system_monitor
        assert Keyword.get(opts, :dirs) == ["/path"]
        {:ok, self()}
      end)
      |> expect(:subscribe, fn :lvdbg_file_system_monitor -> :ok end)

      assert {:noreply, []} = TracingManager.handle_info(:setup_tracing, [])
    end

    test "handles TracingRefreshed event" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      # Should call trace_pattern for Phoenix.LiveView.Diff.delete_component (1 call)
      # Plus 2 calls per callback (return_trace and exception_trace)
      # For LiveView callbacks: 9 callbacks * 2 = 18 calls
      # Total: 1 + 18 = 19 calls
      expect(MockAPIDbg, :trace_pattern, 19, fn _, _ -> :ok end)

      event = %UserRefreshedTrace{}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles LiveViewBorn event" do
      pid = :c.pid(0, 1, 0)
      transport_pid = :c.pid(0, 2, 0)

      MockAPIDbg
      |> expect(:process, fn ^pid, [:s] -> :ok end)

      event = %LiveViewBorn{pid: pid, transport_pid: transport_pid}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles file_event event" do
      MockAPIModule
      |> expect(:loaded?, fn Enum -> true end)
      |> expect(:live_module?, fn Enum -> true end)
      |> stub(:behaviours, fn Enum -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:trace_pattern, 18, fn _, _ -> :ok end)

      event = {:file_event, self(), {"/app/ebin/Elixir.Enum.beam", [:modified]}}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles unknown event" do
      assert {:noreply, []} = TracingManager.handle_info(:unknown_event, [])
    end
  end
end
