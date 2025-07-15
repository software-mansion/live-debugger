defmodule LiveDebuggerRefactor.Services.CallbackTracer.Supervisor do
  @moduledoc """
  Supervisor for CallbackTracer service.
  """

  use Supervisor

  def start_link(opts \\ []) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end
end
