defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.
  """

  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.API.System.Dbg
  alias LiveDebugger.API.SettingsStorage

  @spec setup_tracing!() :: :ok
  def setup_tracing!() do
    case Dbg.tracer({&Tracer.handle_trace/2, 0}) do
      {:ok, pid} ->
        Process.link(pid)

      {:error, error} ->
        raise "Couldn't start tracer: #{inspect(error)}"
    end

    Dbg.process([:c, :timestamp])
    apply_trace_patterns()

    if SettingsStorage.get(:tracing_update_on_code_reload) do
      Dbg.trace_pattern(
        {Mix.Tasks.Compile.Elixir, :run, 1},
        Dbg.flag_to_match_spec(:return_trace)
      )
    end

    :ok
  end

  @spec start_tracing_recompile_pattern() :: :ok
  def start_tracing_recompile_pattern() do
    Dbg.trace_pattern({Mix.Tasks.Compile.Elixir, :run, 1}, Dbg.flag_to_match_spec(:return_trace))

    :ok
  end

  @spec stop_tracing_recompile_pattern() :: :ok
  def stop_tracing_recompile_pattern() do
    Dbg.clear_trace_pattern({Mix.Tasks.Compile.Elixir, :run, 1})

    :ok
  end

  @spec refresh_tracing() :: :ok
  def refresh_tracing() do
    apply_trace_patterns()

    :ok
  end

  defp apply_trace_patterns() do
    # This is not a callback created by user
    # We trace it to refresh the components tree
    Dbg.trace_pattern({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    CallbackQueries.all_callbacks()
    |> Enum.each(fn mfa ->
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:return_trace))
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:exception_trace))
    end)
  end
end
