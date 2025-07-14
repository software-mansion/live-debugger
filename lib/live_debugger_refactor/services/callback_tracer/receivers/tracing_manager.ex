defmodule LiveDebuggerRefactor.Services.CallbackTracer.Receivers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebuggerRefactor.API.System.Dbg
  alias LiveDebuggerRefactor.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries

  @tracing_setup_delay Application.compile_env(:live_debugger, :tracing_setup_delay, 0)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Process.send_after(self(), :setup_tracing, @tracing_setup_delay)

    {:ok, opts}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    # Start tracer
    Dbg.tracer({&tracer_function/2, 0})

    # Enable tracing for all processes
    Dbg.process([:c, :timestamp])

    # Apply trace patterns for all LiveView and LiveComponent callbacks
    CallbackQueries.all_callbacks()
    |> Enum.each(fn mfa ->
      Dbg.trace_pattern(mfa, [{:_, [], [{:return_trace}]}])
      Dbg.trace_pattern(mfa, [{:_, [], [{:exception_trace}]}])
    end)

    {:noreply, state}
  end

  defp tracer_function(_args, n) do
    dbg("New rough trace")
    n - 1
  end
end
