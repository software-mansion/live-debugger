defmodule LiveDebugger.SystemCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias LiveDebugger.MockProcessService

  setup do
    live_view_pid = :c.pid(0, 0, 0)
    socket_id = "phx-GBsi_6M7paYhySQj"

    Mox.stub(MockProcessService, :state, fn pid ->
      if live_view_pid == pid do
        {:ok, LiveDebugger.Test.Fakes.state(socket_id: socket_id, root_pid: live_view_pid)}
      else
        {:ok, :not_live_view}
      end
    end)

    {:ok, pid: live_view_pid, socket_id: socket_id}
  end
end
