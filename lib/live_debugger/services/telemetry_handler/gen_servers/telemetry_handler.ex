defmodule LiveDebugger.Services.TelemetryHandler.GenServers.TelemetryHandler do
  @moduledoc """
  This module handles telemetry events from debugged application.
  """

  use GenServer

  alias LiveDebugger.Utils.Versions
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.Utils.Modules, as: UtilsModules

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.TelemetryHandler.Events.TelemetryEmitted
  alias LiveDebugger.Services.TelemetryHandler.Events.StateChanged

  @spec start_link(opts :: list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    attach_telemetry_handlers()

    {:ok, []}
  end

  @impl true
  def handle_info({:handle_component_destroyed, pid, cid}, state) do
    save_lv_state!(pid)

    Bus.broadcast_event!(
      %TelemetryEmitted{source: :live_component, type: :destroyed, pid: pid, cid: cid},
      pid
    )

    {:noreply, state}
  end

  defp attach_telemetry_handlers() do
    :telemetry.detach("live-debugger-telemetry-handlers")

    :telemetry.attach_many(
      "live-debugger-telemetry-handlers",
      if Versions.live_component_destroyed_telemetry_supported?() do
        [[:phoenix, :live_component, :destroyed]]
      else
        []
      end,
      &__MODULE__.handle_telemetry/4,
      self()
    )
  end

  def handle_telemetry(
        [:phoenix, :live_component, :destroyed],
        _measurements,
        metadata,
        manager_pid
      ) do
    if not UtilsModules.debugger_module?(metadata.component) do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: metadata.cid}

      send(manager_pid, {:handle_component_destroyed, pid, cid})
    end
  end

  defp save_lv_state!(pid) do
    with {:ok, lv_state} <- LiveViewDebug.liveview_state(pid) do
      StatesStorage.save!(lv_state)
      Bus.broadcast_state!(%StateChanged{pid: pid}, pid)
      :ok
    end
  end
end
