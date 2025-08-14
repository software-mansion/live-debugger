defmodule LiveDebuggerRefactor.Services.CallbackTracer.Actions.TracingTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.Services.CallbackTracer.Actions.Tracing, as: TracingActions
  alias LiveDebuggerRefactor.MockAPIDbg
  alias LiveDebuggerRefactor.MockAPIModule
  alias LiveDebuggerRefactor.MockAPISettingsStorage

  setup :verify_on_exit!

  describe "setup_tracing!/0" do
    test "successfully sets up tracing with tracing_update_on_code_reload set to false" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn {_handler, 0} -> {:ok, self()} end)
      |> expect(:process, fn [:c, :timestamp] -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> false end)

      # Should not call trace_pattern for Mix.Tasks.Compile.Elixir when setting is false
      assert :ok = TracingActions.setup_tracing!()
    end

    test "successfully sets up tracing with tracing_update_on_code_reload set to true" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn {_handler, 0} -> {:ok, self()} end)
      |> expect(:process, fn [:c, :timestamp] -> :ok end)
      |> expect(:trace_pattern, 20, fn _, _ -> :ok end)

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> true end)

      # Should call trace_pattern for Mix.Tasks.Compile.Elixir when setting is true
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

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> false end)

      assert :ok = TracingActions.setup_tracing!()

      # Verify process is linked
      assert Process.info(self(), :links) |> elem(1) |> Enum.member?(tracer_pid)
    end
  end

  describe "start_tracing_recompile_pattern/0" do
    test "starts tracing for Mix.Tasks.Compile.Elixir" do
      MockAPIDbg
      |> expect(:trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1}, _flag -> :ok end)

      assert :ok = TracingActions.start_tracing_recompile_pattern()
    end
  end

  describe "stop_tracing_recompile_pattern/0" do
    test "stops tracing for Mix.Tasks.Compile.Elixir" do
      MockAPIDbg
      |> expect(:clear_trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1} -> :ok end)

      assert :ok = TracingActions.stop_tracing_recompile_pattern()
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
end
