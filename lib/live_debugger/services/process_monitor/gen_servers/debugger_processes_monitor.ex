defmodule LiveDebugger.Services.ProcessMonitor.GenServers.DebuggerProcessesMonitor do
  @moduledoc """
  This module is monitoring the status of the debugger LiveView processes monitoring debugged LiveView process.

  `DebuggerTerminated` event is detected when a monitored debugger process sends a `:DOWN` message.
  """

  use GenServer

  alias LiveDebugger.App.Events.DebuggerMounted
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.ProcessMonitor.Events.DebuggerTerminated

  require Logger

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Bus.receive_events!()

    {:ok, []}
  end

  @impl true
  def handle_info(%DebuggerMounted{debugger_pid: debugger_pid}, state) do
    Process.monitor(debugger_pid)

    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
    Bus.broadcast_event!(%DebuggerTerminated{debugger_pid: pid})

    {:noreply, state}
  end

  def handle_info(_, state), do: {:noreply, state}
end
