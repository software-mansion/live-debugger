defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TracingManager do
  @moduledoc """
  Manages the tracing of callbacks.
  """

  use GenServer

  alias LiveDebuggerRefactor.API.System.Dbg
  alias LiveDebuggerRefactor.API.SettingsStorage
  alias LiveDebuggerRefactor.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebuggerRefactor.Services.CallbackTracer.Process.Tracer

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.SettingsChanged
  alias LiveDebuggerRefactor.App.Events.TracingRefreshed

  @tracing_setup_delay Application.compile_env(:live_debugger, :tracing_setup_delay, 0)

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(opts) do
    Bus.receive_events!()
    Process.send_after(self(), :setup_tracing, @tracing_setup_delay)

    {:ok, opts}
  end

  @impl true
  def handle_info(:setup_tracing, state) do
    case Dbg.tracer({&Tracer.handle_trace/2, 0}) do
      {:ok, pid} ->
        Process.link(pid)

      {:error, error} ->
        raise "Couldn't start tracer: #{inspect(error)}"
    end

    Dbg.process([:c, :timestamp])
    apply_trace_patterns()

    if SettingsStorage.get(:tracing_update_on_code_reload) do
      Dbg.trace_pattern({Mix.Tasks.Compile.Elixir, :run, 1}, [{:_, [], [{:return_trace}]}])
    end

    {:noreply, state}
  end

  @impl true
  def handle_info(%SettingsChanged{key: :tracing_update_on_code_reload, value: true}, state) do
    Dbg.trace_pattern({Mix.Tasks.Compile.Elixir, :run, 1}, Dbg.flag_to_match_spec(:return_trace))

    {:noreply, state}
  end

  @impl true
  def handle_info(%SettingsChanged{key: :tracing_update_on_code_reload, value: false}, state) do
    Dbg.clear_trace_pattern({Mix.Tasks.Compile.Elixir, :run, 1})

    {:noreply, state}
  end

  @impl true
  def handle_info(%TracingRefreshed{}, state) do
    apply_trace_patterns()

    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp apply_trace_patterns() do
    CallbackQueries.all_callbacks()
    |> Enum.each(fn mfa ->
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:return_trace))
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:exception_trace))
    end)
  end
end
