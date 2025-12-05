defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.
  """
  require Logger

  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.API.System.Dbg
  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Modules, as: UtilsModules
  alias LiveDebugger.Services.CallbackTracer.Queries.Paths, as: PathQueries

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
    monitor_recompilation()

    :ok
  end

  @spec refresh_tracing() :: :ok
  def refresh_tracing() do
    apply_trace_patterns()

    :ok
  end

  @spec refresh_tracing(String.t()) :: :ok
  def refresh_tracing(path) do
    with true <- beam_file?(path),
         module <- path |> Path.basename(".beam") |> String.to_existing_atom(),
         true <- ModuleAPI.loaded?(module),
         false <- UtilsModules.debugger_module?(module),
         true <- ModuleAPI.live_module?(module) do
      refresh_tracing_for_module(module)
    end

    :ok
  end

  defp refresh_tracing_for_module(module) do
    module
    |> CallbackQueries.all_callbacks()
    |> case do
      {:error, error} ->
        Logger.error("Error refreshing tracing for module #{module}: #{error}")

      callbacks ->
        callbacks
        |> Enum.each(fn mfa ->
          Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:return_trace))
          Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:exception_trace))
        end)
    end
  end

  @spec start_outgoing_messages_tracing(pid()) :: :ok
  def start_outgoing_messages_tracing(pid) do
    Dbg.process(pid, [:s])

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

  defp monitor_recompilation() do
    directories = PathQueries.compiled_modules_directories()
    FileSystem.start_link(dirs: directories, name: :lvdbg_file_system_monitor)
    FileSystem.subscribe(:lvdbg_file_system_monitor)

    :ok
  end

  defp beam_file?(path) do
    String.ends_with?(path, ".beam")
  end
end
