defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManagerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebuggerRefactor.MockBus
  alias LiveDebuggerRefactor.MockAPIDbg
  alias LiveDebuggerRefactor.MockAPIModule
  alias LiveDebuggerRefactor.MockAPISettingsStorage
  alias LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManager

  alias LiveDebuggerRefactor.App.Events.SettingsChanged
  alias LiveDebuggerRefactor.App.Events.TracingRefreshed

  setup :verify_on_exit!

  describe "init/1" do
    test "sets up the tracing manager properly" do
      expect(MockBus, :receive_events!, fn -> :ok end)
      assert {:ok, []} = TracingManager.init([])

      assert_receive :setup_tracing
    end
  end

  describe "handle_info/2" do
    test "handles :setup_tracing event with tracing_update_on_code_reload set to false" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn _ -> {:ok, self()} end)
      |> expect(:process, fn _ -> :ok end)
      |> expect(:trace_pattern, 18, fn _, _ -> :ok end)

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> false end)

      assert {:noreply, []} = TracingManager.handle_info(:setup_tracing, [])
    end

    test "handles :setup_tracing event with tracing_update_on_code_reload set to true" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      MockAPIDbg
      |> expect(:tracer, fn _ -> {:ok, self()} end)
      |> expect(:process, fn _ -> :ok end)
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      expect(MockAPISettingsStorage, :get, fn :tracing_update_on_code_reload -> true end)

      assert {:noreply, []} = TracingManager.handle_info(:setup_tracing, [])
    end

    test "handles SettingsChanged event with tracing_update_on_code_reload set to true" do
      expect(MockAPIDbg, :trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1}, _ -> :ok end)

      event = %SettingsChanged{key: :tracing_update_on_code_reload, value: true}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles SettingsChanged event with tracing_update_on_code_reload set to false" do
      expect(MockAPIDbg, :clear_trace_pattern, fn {Mix.Tasks.Compile.Elixir, :run, 1} -> :ok end)

      event = %SettingsChanged{key: :tracing_update_on_code_reload, value: false}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end

    test "handles TracingRefreshed event" do
      MockAPIModule
      |> expect(:all, fn -> [{~c"Test.LiveViewModule", ~c"/path", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      expect(MockAPIDbg, :trace_pattern, 18, fn _, _ -> :ok end)

      event = %TracingRefreshed{}

      assert {:noreply, []} = TracingManager.handle_info(event, [])
    end
  end
end
