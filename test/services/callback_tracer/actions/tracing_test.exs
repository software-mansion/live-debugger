defmodule LiveDebugger.Services.CallbackTracer.Actions.TracingTest do
  use ExUnit.Case, async: true

  import Mox

  # These params are defined here to prevent errors associated with String.to_existing_atom/1
  @live_view_module :"Elixir.TracingTestLiveView"
  @live_component_module :"Elixir.TracingTestLiveComponent"

  alias LiveDebugger.Services.CallbackTracer.Actions.Tracing, as: TracingActions
  alias LiveDebugger.MockAPIDbg
  alias LiveDebugger.MockAPIModule

  setup :verify_on_exit!

  describe "setup_tracing!/0" do
    test "successfully sets up tracing" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn {_handler, 0} -> {:ok, self()} end)
      |> expect(:process, fn [:c, :timestamp] -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      assert :ok = TracingActions.setup_tracing!()
    end

    test "raises error when tracer fails to start" do
      MockAPIDbg
      |> expect(:tracer, fn {_handler, 0} -> {:error, :already_started} end)

      assert_raise RuntimeError, "Couldn't start tracer: :already_started", fn ->
        TracingActions.setup_tracing!()
      end
    end

    test "links to tracer process when successful" do
      tracer_pid =
        spawn(fn ->
          receive do
            _ -> :ok
          end
        end)

      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn {_handler, 0} -> {:ok, tracer_pid} end)
      |> expect(:process, fn [:c, :timestamp] -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      assert :ok = TracingActions.setup_tracing!()

      # Verify process is linked
      assert Process.info(self(), :links) |> elem(1) |> Enum.member?(tracer_pid)
    end
  end

  describe "refresh_tracing/0" do
    test "applies trace patterns for all callbacks" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      expect(MockAPIDbg, :trace_pattern, 19, fn _, _ -> :ok end)

      assert :ok = TracingActions.refresh_tracing()
    end

    test "handles empty callbacks list" do
      MockAPIModule
      |> expect(:all, fn -> [] end)

      expect(MockAPIDbg, :trace_pattern, 1, fn _, _ -> :ok end)

      assert :ok = TracingActions.refresh_tracing()
    end

    test "applies both return_trace and exception_trace for each callback" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      # Should call trace_pattern for Phoenix.LiveView.Diff.delete_component (1 call)
      # Plus 2 calls per callback (return_trace and exception_trace)
      # For LiveView callbacks: 9 callbacks * 2 = 18 calls
      # Total: 1 + 18 = 19 calls
      expect(MockAPIDbg, :trace_pattern, 19, fn _, _ -> :ok end)

      assert :ok = TracingActions.refresh_tracing()
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
