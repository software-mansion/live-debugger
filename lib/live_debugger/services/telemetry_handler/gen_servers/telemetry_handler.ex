defmodule LiveDebugger.Services.TelemetryHandler.GenServers.TelemetryHandler do
  @moduledoc """
  This module handles telemetry events from debugged application.
  """

  use GenServer

  alias LiveDebugger.Services.TelemetryHandler.Events.TelemetryEmitted
  alias LiveDebugger.Utils.Modules, as: UtilsModules

  alias LiveDebugger.Bus

  @spec start_link(opts :: list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    attach()

    {:ok, []}
  end

  defp attach() do
    :telemetry.attach_many(
      "live-debugger-telemetry-handlers",
      [
        [:phoenix, :live_view, :mount, :start],
        [:phoenix, :live_view, :handle_params, :start],
        [:phoenix, :live_view, :handle_event, :start],
        [:phoenix, :live_view, :render, :start],
        [:phoenix, :live_component, :update, :start],
        [:phoenix, :live_component, :handle_event, :start]
      ],
      &__MODULE__.handle_telemetry/4,
      nil
    )
  end

  def handle_telemetry([:phoenix, source, type, stage], _measurements, metadata, _config) do
    if not UtilsModules.debugger_module?(metadata.socket.view) do
      pid = self()

      cid =
        if Map.has_key?(metadata, :cid) do
          %Phoenix.LiveComponent.CID{cid: metadata.cid}
        else
          nil
        end

      Bus.broadcast_event!(%TelemetryEmitted{
        source: source,
        type: type,
        stage: stage,
        pid: pid,
        cid: cid,
        transport_pid: metadata.socket.transport_pid
      })
    end
  end
end
