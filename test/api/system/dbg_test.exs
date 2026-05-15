defmodule LiveDebugger.API.System.DbgTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias LiveDebugger.API.System.Dbg

  describe "flag_to_match_spec/1" do
    test "converts a single flag to match spec format" do
      assert [{:_, [], [{:return_trace}]}] = Dbg.flag_to_match_spec(:return_trace)
    end

    test "exception for invalid flag" do
      assert_raise FunctionClauseError, fn ->
        Dbg.flag_to_match_spec(:invalid_flag)
      end
    end
  end

  # These exercise the real `Impl` rather than the global Mox stub. They touch
  # BEAM-wide tracing state (registered names, trace flags), so they must not
  # run in parallel with each other or anything else that traces.
  describe "Impl lifecycle" do
    @impl_mod LiveDebugger.API.System.Dbg.Impl
    @tracer_name :live_debugger_tracer

    setup do
      on_exit(fn -> @impl_mod.stop() end)
      :ok
    end

    test "tracer/1 starts a tracer process and registers it" do
      assert {:ok, pid} = @impl_mod.tracer({fn _msg, n -> n end, 0})
      assert Process.alive?(pid)
      assert Process.whereis(@tracer_name) == pid
    end

    test "tracer/1 returns :already_started when one is running" do
      assert {:ok, _pid} = @impl_mod.tracer({fn _msg, n -> n end, 0})
      assert {:error, :already_started} = @impl_mod.tracer({fn _msg, n -> n end, 0})
    end

    test "process/1 errors when no tracer is running" do
      assert {:error, :tracer_not_started} = @impl_mod.process([:c])
    end

    test "process/2 errors when no tracer is running" do
      assert {:error, :tracer_not_started} = @impl_mod.process(self(), [:s])
    end

    test "stop/0 is idempotent" do
      assert :ok = @impl_mod.stop()
      assert :ok = @impl_mod.stop()
    end

    test "stop/0 terminates the tracer and unregisters the name" do
      assert {:ok, pid} = @impl_mod.tracer({fn _msg, n -> n end, 0})
      assert :ok = @impl_mod.stop()
      refute Process.alive?(pid)
      assert Process.whereis(@tracer_name) == nil
    end

    test "trace_pattern/2 on a missing module returns {:ok, 0}" do
      assert {:ok, 0} = @impl_mod.trace_pattern(:"Elixir.NoSuchModuleXYZ", [])
    end

    test "trace_pattern/2 on a bad MFA returns an :error tuple" do
      assert {:error, {:error, :badarg}} = @impl_mod.trace_pattern({1, 2, 3}, [])
    end
  end
end
