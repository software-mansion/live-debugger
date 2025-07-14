defmodule LiveDebuggerRefactor.Services.CallbackTracer.Receivers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end
end
