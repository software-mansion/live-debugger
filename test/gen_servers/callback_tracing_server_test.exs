defmodule LiveDebugger.GenServers.CallbackTracingServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.GenServers.CallbackTracingServer
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.MockModuleService
  alias LiveDebugger.MockDbg
  alias LiveDebugger.MockEtsTableServer
  alias LiveDebugger.MockPubSubUtils
  alias LiveDebugger.MockStateServer

  @modules [
    CoolApp.LiveViews.UserDashboard,
    CoolApp.Service.UserService,
    CoolApp.LiveComponent.UserElement
  ]

  setup :verify_on_exit!

  test "init/1" do
    assert {:ok, %{}} = CallbackTracingServer.init([])
    assert_receive :setup_tracing
  end

  test "handle_call/3" do
    assert {:reply, :ok, %{}} == CallbackTracingServer.handle_call(:ping, self(), %{})
  end

  test "proper tracing setup" do
    MockModuleService
    |> expect(:all, fn ->
      Enum.map(@modules, fn module -> {to_charlist(module), ~c"", false} end)
    end)
    |> expect(:loaded?, 6, fn _module -> true end)
    |> expect(:behaviours, 6, fn module -> get_behaviours(module) end)

    MockDbg
    |> expect(:tracer, fn :process, {_handler, 0} -> :ok end)
    |> expect(:p, fn :all, [:c, :timestamp] -> :ok end)

    get_live_component_callbacks(CoolApp.LiveComponent.UserElement)
    |> Enum.concat(get_live_view_callbacks(CoolApp.LiveViews.UserDashboard))
    |> Enum.each(fn mfa ->
      expect(MockDbg, :tp, fn ^mfa, [{:_, [], [{:return_trace}]}] -> :ok end)
      expect(MockDbg, :tp, fn ^mfa, [{:_, [], [{:exception_trace}]}] -> :ok end)
    end)

    MockDbg
    |> expect(:tp, fn {Phoenix.LiveView.Diff, :delete_component, 2}, [] -> :ok end)

    assert {:noreply, %{}} = CallbackTracingServer.handle_info(:setup_tracing, %{})
  end

  describe "tracing mechanism" do
    setup do
      MockModuleService
      |> expect(:all, fn -> [] end)

      MockDbg
      |> expect(:p, fn :all, [:c, :timestamp] -> :ok end)
      |> expect(:tp, fn {Phoenix.LiveView.Diff, :delete_component, 2}, [] -> :ok end)

      # In order to keep CallbackTracingServer.handle_trace function private we extract it here
      # and send to test process so that we can test it
      |> expect(:tracer, fn :process, {handle_trace, 0} -> send(self(), handle_trace) end)

      :ok
    end

    test "handle delete component trace" do
      parent = self()
      transport_pid = :c.pid(0, 0, 1)
      pid = :c.pid(0, 0, 2)
      cid = 3
      socket_id = "phx-GDrDzLLr4USWzwBC"
      module = Phoenix.LiveView.Diff
      fun = :delete_component
      args = [cid, %{}]

      component_deleted_topic =
        PubSubUtils.component_deleted_topic(%{socket_id: socket_id, transport_pid: transport_pid})

      component_deleted_all_topic =
        PubSubUtils.component_deleted_topic()

      MockStateServer
      |> expect(:get, fn ^pid ->
        {:ok, LiveDebugger.Fakes.state(transport_pid: transport_pid, socket_id: socket_id)}
      end)

      MockPubSubUtils
      |> expect(:broadcast, fn ^component_deleted_topic, {:component_deleted, trace} ->
        send(parent, {:trace1, trace})
      end)
      |> expect(:broadcast, fn ^component_deleted_all_topic, {:component_deleted, trace} ->
        send(parent, {:trace2, trace})
      end)

      assert {:noreply, %{}} = CallbackTracingServer.handle_info(:setup_tracing, %{})
      assert_receive handle_trace
      assert 0 = handle_trace.({:trace, pid, :call, {module, fun, args}, :erlang.timestamp()}, 0)
      assert_receive {:trace1, trace}
      assert_receive {:trace2, ^trace}

      assert %Trace{
               id: 0,
               module: ^module,
               function: ^fun,
               arity: 2,
               args: ^args,
               socket_id: ^socket_id,
               transport_pid: ^transport_pid,
               pid: ^pid,
               cid: %Phoenix.LiveComponent.CID{cid: ^cid}
             } = trace
    end

    test "handle standard live view trace" do
      transport_pid = :c.pid(0, 0, 1)
      pid = :c.pid(0, 0, 2)
      socket_id = "phx-GDrDzLLr4USWzwBC"
      module = CoolApp.LiveViews.UserDashboard
      fun = :handle_info

      args = [
        :msg,
        %{transport_pid: transport_pid, socket: %Phoenix.LiveView.Socket{id: socket_id}}
      ]

      table = :ets.new(:test_table, [:ordered_set, :public])

      expected_tsnf_topic = PubSubUtils.tsnf_topic(socket_id, transport_pid, pid, fun)
      expected_ts_f_topic = PubSubUtils.ts_f_topic(socket_id, transport_pid, fun)

      MockEtsTableServer
      |> expect(:table!, fn ^pid -> table end)

      MockPubSubUtils
      |> expect(:broadcast, fn ^expected_tsnf_topic, {:new_trace, _trace} -> :ok end)
      |> expect(:broadcast, fn ^expected_ts_f_topic, {:new_trace, _trace} -> :ok end)

      assert {:noreply, %{}} = CallbackTracingServer.handle_info(:setup_tracing, %{})
      assert_receive handle_trace
      assert -1 = handle_trace.({:trace, pid, :call, {module, fun, args}, :erlang.timestamp()}, 0)
      assert [{0, trace}] = :ets.tab2list(table)

      assert %Trace{
               id: 0,
               module: ^module,
               function: ^fun,
               arity: 2,
               args: ^args,
               socket_id: ^socket_id,
               transport_pid: ^transport_pid,
               pid: ^pid,
               cid: nil
             } = trace
    end

    test "handle unexpected trace" do
      assert {:noreply, %{}} = CallbackTracingServer.handle_info(:setup_tracing, %{})
      assert_receive handle_trace
      assert 0 == handle_trace.({:_, :c.pid(0, 0, 1), :_, {SomeModule, :some_func, []}}, 0)
    end
  end

  defp get_behaviours(module) do
    case module do
      CoolApp.LiveViews.UserDashboard -> [Phoenix.LiveView]
      CoolApp.Service.UserService -> []
      CoolApp.LiveComponent.UserElement -> [Phoenix.LiveComponent]
    end
  end

  defp get_live_view_callbacks(module) do
    [
      {module, :mount, 3},
      {module, :handle_params, 3},
      {module, :handle_info, 2},
      {module, :handle_call, 3},
      {module, :handle_cast, 2},
      {module, :terminate, 2},
      {module, :render, 1},
      {module, :handle_event, 3},
      {module, :handle_async, 3}
    ]
  end

  defp get_live_component_callbacks(module) do
    [
      {module, :mount, 1},
      {module, :update, 2},
      {module, :update_many, 1},
      {module, :render, 1},
      {module, :handle_event, 3},
      {module, :handle_async, 3}
    ]
  end
end
