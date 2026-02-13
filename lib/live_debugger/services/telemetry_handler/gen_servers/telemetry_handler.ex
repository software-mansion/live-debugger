defmodule LiveDebugger.Services.TelemetryHandler.GenServers.TelemetryHandler do
  @moduledoc """
  This module handles telemetry events from debugged application.
  """

  use GenServer

  alias LiveDebugger.Utils.Modules, as: UtilsModules

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.TelemetryHandler.Events.LiveComponentDeleted

  @live_view_vsn Application.spec(:phoenix_live_view, :vsn) |> to_string()

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
      # Telemetry for destroyed components was introduced in Phoenix LiveView 1.1.0.
      if Version.match?(@live_view_vsn, ">= 1.1.0-rc.0") do
        [[:phoenix, :live_component, :destroyed]]
      else
        []
      end,
      &__MODULE__.handle_telemetry/4,
      nil
    )
  end

  def handle_telemetry([:phoenix, :live_component, :destroyed], _measurements, metadata, _config) do
    if not UtilsModules.debugger_module?(metadata.component) do
      pid = self()
      cid = %Phoenix.LiveComponent.CID{cid: metadata.cid}

      Bus.broadcast_event!(%LiveComponentDeleted{pid: pid, cid: cid}, pid)
    end
  end
end
