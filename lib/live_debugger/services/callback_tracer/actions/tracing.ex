defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.
  """
  require Logger

  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager
  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebugger.Services.CallbackTracer.Queries.Traces, as: TraceQueries
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.API.System.FileSystem, as: FileSystemAPI
  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Modules, as: UtilsModules
  alias LiveDebugger.API.System.Dbg

  @doc """
  Sets up tracing and monitors recompilation in a single pass.
  Fetches and processes the module list only once for efficiency.
  """
  @spec setup_tracing_with_monitoring!(TracingManager.state()) :: TracingManager.state()
  def setup_tracing_with_monitoring!(state) do
    last_id = TraceQueries.get_last_trace_id()

    case Dbg.tracer({&Tracer.handle_trace/2, last_id - 1}) do
      {:ok, pid} ->
        Process.monitor(pid)

        Dbg.process([:c, :timestamp, :procs])

        # Fetch all live modules once with paths for both operations
        live_modules_with_paths = CallbackQueries.all_live_modules_with_paths()

        # Extract just the module names for callback queries
        module_names = Enum.map(live_modules_with_paths, fn {module, _path} -> module end)

        # Apply trace patterns using the fetched modules
        apply_trace_patterns(module_names)

        # Monitor recompilation using the paths
        start_file_monitoring(live_modules_with_paths)

        %{state | dbg_pid: pid}

      {:error, error} ->
        raise "Couldn't start tracer: #{inspect(error)}"
    end
  end

  @spec refresh_tracing() :: :ok
  def refresh_tracing() do
    Dbg.stop()

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

  @spec start_outgoing_messages_tracing(pid()) :: :ok
  def start_outgoing_messages_tracing(pid) do
    Dbg.process(pid, [:s])

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

  defp apply_trace_patterns(modules) do
    # This is not a callback created by user
    # We trace it to refresh the components tree
    Dbg.trace_pattern({Phoenix.LiveView.Diff, :delete_component, 2}, [])

    modules
    |> CallbackQueries.all_callbacks()
    |> Enum.each(fn mfa ->
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:return_trace))
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:exception_trace))
    end)
  end

  defp start_file_monitoring(live_modules_with_paths) do
    directories =
      live_modules_with_paths
      |> Enum.map(fn {_, path} -> Path.dirname(path) end)
      |> Enum.uniq()

    case Process.whereis(:lvdbg_file_system_monitor) do
      nil ->
        FileSystemAPI.start_link(dirs: directories, name: :lvdbg_file_system_monitor)
        FileSystemAPI.subscribe(:lvdbg_file_system_monitor)
        :ok

      _pid ->
        :ok
    end
  end

  defp beam_file?(path) do
    String.ends_with?(path, ".beam")
  end
end
