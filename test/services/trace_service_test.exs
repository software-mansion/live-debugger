defmodule Services.TraceServiceTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Services.TraceService

  setup_all do
    LiveDebugger.MockModuleService
    |> stub(:all, fn -> [] end)

    allow(LiveDebugger.MockModuleService, self(), fn ->
      GenServer.whereis(LiveDebugger.GenServers.CallbackTracingServer)
    end)

    LiveDebugger.GenServers.CallbackTracingServer.start_link()

    %{
      module: CoolApp.LiveViews.UserDashboard
    }
  end

  test "a", %{module: module} do
    pid = spawn(fn -> :ok end)

    trace = Trace.new(1, module, :render, [], pid)

    assert true == TraceService.insert(trace)

    send(pid, :stop)
  end
end
