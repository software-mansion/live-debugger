defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler do
  @moduledoc """
  GenServer for handling trace data.
  """

  use GenServer

  @spec start_link(opts :: list()) :: GenServer.on_start()
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  It sends a raw trace from `:dbg.tracer` process to the GenServer.
  """
  @spec send_trace(trace :: term(), n :: integer()) :: :ok
  def send_trace(trace, n) do
    GenServer.cast(__MODULE__, {:new_trace, trace, n})
  end

  @impl true
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  def handle_cast({:new_trace, trace, n}, state) do
    dbg(trace)
    dbg(n)
    {:noreply, state}
  end
end
