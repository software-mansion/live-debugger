defmodule LiveDebugger.Services.CallbackTracer.GenServers.TracingManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.MockBus
  alias LiveDebugger.MockAPIDbg
  alias LiveDebugger.MockAPIFileSystem
  alias LiveDebugger.MockAPIModule
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager

  alias LiveDebugger.App.Events.UserRefreshedTrace
  alias LiveDebugger.Services.ProcessMonitor.Events.LiveViewBorn

  setup :verify_on_exit!

  describe "init/1" do
    test "sets up the tracing manager properly" do
      expect(MockBus, :receive_events!, fn -> :ok end)

      assert {:ok, %{dbg_pid: nil}} = TracingManager.init([])

      assert_receive :setup_tracing
    end
  end

  describe "handle_info/2" do
    test "handles :setup_tracing event" do
      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      MockAPIModule
      |> expect(:all, 2, fn -> [{~c"Test.LiveViewModule", ~c"/path/Module.beam", true}] end)
      |> expect(:loaded?, 2, fn _ -> true end)
      |> expect(:live_module?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIFileSystem
      |> expect(:start_link, fn opts ->
        assert Keyword.get(opts, :name) == :lvdbg_file_system_monitor
        assert Keyword.get(opts, :dirs) == ["/path"]
        {:ok, self()}
      end)
      |> expect(:subscribe, fn :lvdbg_file_system_monitor -> :ok end)

      MockAPIDbg
      |> expect(:tracer, fn _ -> {:ok, self()} end)
      |> expect(:process, fn _ -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      assert {:noreply, %{dbg_pid: self()}} ==
               TracingManager.handle_info(:setup_tracing, %{dbg_pid: nil})
    end

    test "handles TracingRefreshed event" do
      expect(MockAPIDbg, :stop, fn -> :ok end)

      event = %UserRefreshedTrace{}

      assert {:noreply, %{dbg_pid: self()}} ==
               TracingManager.handle_info(event, %{dbg_pid: self()})
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
