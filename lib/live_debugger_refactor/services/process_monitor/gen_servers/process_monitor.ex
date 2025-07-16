defmodule LiveDebuggerRefactor.Services.ProcessMonitor.GenServers.ProcessMonitor do
  @moduledoc """
  This module is monitoring the status of LiveView processes created by a debugged application.
  """

  use GenServer

  alias LiveDebuggerRefactor.CommonTypes
  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.ProcessMonitor.Actions
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned

  import LiveDebuggerRefactor.Services.Helpers

  @type state :: %{
          pid() => MapSet.t(CommonTypes.cid())
        }

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  @spec init(any()) :: {:ok, state()}
  def init(_opts) do
    # TODO: change to receive_traces!/0
    :ok = Bus.receive_traces()

    ok(%{})
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, cid: cid, context: %{pid: pid}}, state)
      when is_map_key(state, pid) and not is_nil(cid) do
    state
    |> maybe_register_component_created(pid, cid)
    |> noreply()
  end

  @impl true
  def handle_info(%TraceReturned{function: :render, cid: nil, context: %{pid: pid}}, state)
      when not is_map_key(state, pid) do
    state
    |> Actions.register_live_view_born(pid)
    |> noreply()
  end

  @impl true
  def handle_info(
        %TraceCalled{
          module: Phoenix.LiveView.Diff,
          function: :delete_component,
          cid: cid,
          context: %{pid: pid}
        },
        state
      )
      when is_map_key(state, pid) do
    state
    |> maybe_register_component_deleted(pid, cid)
    |> noreply()
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) when is_map_key(state, pid) do
    state
    |> Actions.register_live_view_died(pid)
    |> noreply()
  end

  @impl true
  def handle_info(_, state) do
    noreply(state)
  end

  defp maybe_register_component_created(state, pid, cid) do
    if MapSet.member?(state[pid], cid) do
      state
    else
      state
      |> Actions.register_component_created(pid, cid)
    end
  end

  defp maybe_register_component_deleted(state, pid, cid) do
    if MapSet.member?(state[pid], cid) do
      state
      |> Actions.register_component_deleted(pid, cid)
    else
      state
    end
  end
end
