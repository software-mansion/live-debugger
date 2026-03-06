defmodule LiveDebugger.Services.TelemetryHandler.Supervisor do
  @moduledoc """
  Supervisor for TelemetryHandler service.
  """

  use Supervisor

  alias LiveDebugger.Services.TelemetryHandler.GenServers.TelemetryHandler

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      {TelemetryHandler, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
