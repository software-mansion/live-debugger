defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.MockAPIDbg
  alias LiveDebuggerRefactor.MockAPIModule
  alias LiveDebuggerRefactor.MockAPISettingsStorage
  alias LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManager

  alias LiveDebuggerRefactor.App.Events.UserChangedSettings
  alias LiveDebuggerRefactor.App.Events.UserRefreshedTrace

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
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn _ -> {:ok, self()} end)
      |> expect(:process, fn _ -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> false end)

      assert {:noreply, []} = TracingManager.handle_info(:setup_tracing, [])
    end

    test "handles SettingsChanged event with tracing_update_on_code_reload set to true" do
      expect(MockAPIDbg, :trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1}, _ -> :ok end)

      event = %UserChangedSettings{key: :tracing_update_on_code_reload, value: true}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles SettingsChanged event with tracing_update_on_code_reload set to false" do
      expect(MockAPIDbg, :clear_trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1} -> :ok end)

      event = %UserChangedSettings{key: :tracing_update_on_code_reload, value: false}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
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

    test "handles unknown event" do
      assert {:noreply, []} = TracingManager.handle_info(:unknown_event, [])
    end
  end
end
