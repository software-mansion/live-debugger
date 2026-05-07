defmodule LiveDebugger.Services.CallbackTracer.Actions.TracingTest do
  use ExUnit.Case, async: true

  import Mox

  # These params are defined here to prevent errors associated with String.to_existing_atom/1
  @live_view_module :"Elixir.TracingTestLiveView"
  @live_component_module :"Elixir.TracingTestLiveComponent"

  alias LiveDebugger.MockAPIDbg
  alias LiveDebugger.MockAPIFileSystem
  alias LiveDebugger.MockAPIModule
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.MockBus
  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions
  alias LiveDebugger.Services.CallbackTracer.Events.DbgStarted

  setup :verify_on_exit!

  defp expect_ip_tracer(mock, client_pid) do
    port_fun = fn -> nil end

    mock
    |> expect(:trace_port, fn :ip, {_port, _qsize} -> port_fun end)
    |> expect(:tracer, fn :port, ^port_fun -> {:ok, self()} end)
    |> expect(:trace_client, fn :ip, {~c"localhost", _port}, {_handler, {:init, _}} ->
      client_pid
    end)
  end

  describe "setup_tracing_with_monitoring!/1" do
    test "successfully sets up tracing and monitoring" do
      client_pid = self()

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path/Module.beam", true}] end)
      |> expect(:loaded?, fn _ -> true end)
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
      |> expect_ip_tracer(client_pid)
      |> expect(:process, fn [:c, :timestamp, :procs] -> :ok end)
      |> expect(
        :trace_pattern,
        18,
        fn _, _ -> :ok end
      )

      MockBus
      |> expect(:broadcast_event!, fn %DbgStarted{} -> :ok end)

      assert %{dbg_pid: ^client_pid} =
               TracingActions.setup_tracing_with_monitoring!(%{dbg_pid: nil})
    end

    test "raises error when tracer fails to start" do
      port_fun = fn -> nil end

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      MockAPIDbg
      |> expect(:trace_port, fn :ip, {_port, _qsize} -> port_fun end)
      |> expect(:tracer, fn :port, ^port_fun -> {:error, :already_started} end)

      assert_raise RuntimeError, "Couldn't start tracer: :already_started", fn ->
        TracingActions.setup_tracing_with_monitoring!(%{})
      end
    end

    test "monitors trace_client process when successful" do
      client_pid =
        spawn(fn ->
          receive do
            _ -> :ok
          end
        end)

      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path/Module.beam", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:live_module?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIFileSystem
      |> expect(:start_link, fn opts ->
        assert Keyword.get(opts, :name) == :lvdbg_file_system_monitor
        {:ok, self()}
      end)
      |> expect(:subscribe, fn :lvdbg_file_system_monitor -> :ok end)

      MockAPIDbg
      |> expect_ip_tracer(client_pid)
      |> expect(:process, fn [:c, :timestamp, :procs] -> :ok end)
      |> expect(
        :trace_pattern,
        18,
        fn _, _ -> :ok end
      )

      MockBus
      |> expect(:broadcast_event!, fn %DbgStarted{} -> :ok end)

      assert %{dbg_pid: ^client_pid} =
               TracingActions.setup_tracing_with_monitoring!(%{dbg_pid: nil})

      # Verify the trace_client process is the one being monitored
      Process.exit(client_pid, :done)

      assert_receive {:DOWN, _, :process, ^client_pid, :done}
    end

    test "monitors multiple directories for file changes" do
      MockAPITracesStorage
      |> expect(:get_all_tables, fn -> [] end)

      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/app/views/view.beam", true},
          {~c"Test.LiveComponentModule", ~c"/app/components/component.beam", true}
        ]
      end)
      |> stub(:loaded?, fn _ -> true end)
      |> stub(:live_module?, fn _ -> true end)
      |> stub(:behaviours, fn _ -> [Phoenix.LiveView] end)

      MockAPIFileSystem
      |> expect(:start_link, fn opts ->
        assert Keyword.get(opts, :name) == :lvdbg_file_system_monitor
        dirs = Keyword.get(opts, :dirs)
        assert "/app/views" in dirs
        assert "/app/components" in dirs
        {:ok, self()}
      end)
      |> expect(:subscribe, fn :lvdbg_file_system_monitor -> :ok end)

      MockAPIDbg
      |> expect_ip_tracer(self())
      |> expect(:process, fn [:c, :timestamp, :procs] -> :ok end)
      # 2 modules * 9 LiveView callbacks * 2 (return + exception) = 36
      |> expect(
        :trace_pattern,
        36,
        fn _, _ -> :ok end
      )

      MockBus
      |> expect(:broadcast_event!, fn %DbgStarted{} -> :ok end)

      assert %{dbg_pid: self()} == TracingActions.setup_tracing_with_monitoring!(%{dbg_pid: nil})
    end
  end

  describe "refresh_tracing/1" do
    test "refreshes tracing for a LiveView module" do
      MockAPIModule
      |> expect(:loaded?, fn @live_view_module -> true end)
      |> expect(:live_module?, fn @live_view_module -> true end)
      |> stub(:behaviours, fn @live_view_module -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:trace_pattern, 18, fn _, _ -> :ok end)

      assert :ok = TracingActions.refresh_tracing("/app/ebin/Elixir.TracingTestLiveView.beam")
    end

    test "refreshes tracing for a LiveComponent module" do
      MockAPIModule
      |> expect(:loaded?, fn @live_component_module -> true end)
      |> expect(:live_module?, fn @live_component_module -> true end)
      |> stub(:behaviours, fn @live_component_module -> [Phoenix.LiveComponent] end)

      MockAPIDbg
      |> expect(:trace_pattern, 12, fn _, _ -> :ok end)

      assert :ok =
               TracingActions.refresh_tracing("/app/ebin/Elixir.TracingTestLiveComponent.beam")
    end

    test "does nothing when path is not a .beam file" do
      assert :ok = TracingActions.refresh_tracing("/app/lib/test_module.ex")
      assert :ok = TracingActions.refresh_tracing("/app/lib/test_module.exs")
      assert :ok = TracingActions.refresh_tracing("/app/lib/test_module")
    end

    test "does nothing when module is a debugger module" do
      MockAPIModule
      |> expect(:loaded?, fn LiveDebugger.Bus -> true end)

      assert :ok = TracingActions.refresh_tracing("/app/ebin/Elixir.LiveDebugger.Bus.beam")
    end

    test "does nothing when module is not loaded" do
      # Enum is a real existing atom
      MockAPIModule
      |> expect(:loaded?, fn Enum -> false end)

      assert :ok = TracingActions.refresh_tracing("/app/ebin/Elixir.Enum.beam")
    end

    test "does nothing when module is not a live module" do
      MockAPIModule
      |> expect(:loaded?, fn Enum -> true end)
      |> expect(:live_module?, fn Enum -> false end)

      assert :ok = TracingActions.refresh_tracing("/app/ebin/Elixir.Enum.beam")
    end
  end

  describe "start_outgoing_messages_tracing/1" do
    test "starts outgoing messages tracing for a process" do
      pid = :c.pid(0, 1, 0)

      MockAPIDbg
      |> expect(:process, fn ^pid, [:s] -> :ok end)

      result = TracingActions.start_outgoing_messages_tracing(pid)

      assert :ok = result
    end
  end
end
