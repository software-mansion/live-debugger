defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.
  """
  require Logger

  alias LiveDebugger.API.System.Dbg
  alias LiveDebugger.API.System.FileSystem, as: FileSystemAPI
  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DbgStarted
  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebugger.Services.CallbackTracer.Queries.Traces, as: TraceQueries
  alias LiveDebugger.Utils.Modules, as: UtilsModules

  @doc """
  Sets up tracing and monitors recompilation in a single pass.
  Fetches and processes the module list only once for efficiency.
  """
  @spec setup_tracing_with_monitoring!(TracingManager.state()) :: TracingManager.state()
  def setup_tracing_with_monitoring!(state) do
    last_id = TraceQueries.get_last_trace_id()

    Dbg.stop()

    with {:ok, pid} <- Dbg.tracer({&Tracer.handle_trace/2, {:init, last_id - 1}}),
         {:ok, _} <- Dbg.process([:c, :timestamp]) do
      Process.monitor(pid)

      # Fetch all live modules once with paths for both operations
      live_modules_with_paths = CallbackQueries.all_live_modules_with_paths()

      # Extract just the module names for callback queries
      module_names = Enum.map(live_modules_with_paths, fn {module, _path} -> module end)

      # Apply trace patterns using the fetched modules
      apply_trace_patterns(module_names)

      # Monitor recompilation using the paths
      start_file_monitoring(live_modules_with_paths)

      # Broadcast information
      Bus.broadcast_event!(%DbgStarted{})

      %{state | dbg_pid: pid}
    else
      {:error, error} ->
        Logger.error("Couldn't start tracer: #{inspect(error)}")
        state
    end
  end

  @spec refresh_tracing(String.t()) :: :ok
  def refresh_tracing(path) when is_binary(path) do
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
    case Dbg.process(pid, [:s, :procs]) do
      {:ok, _} ->
        :ok

      {:error, error} ->
        Logger.error("Couldn't enable send tracing for #{inspect(pid)}: #{inspect(error)}")
    end
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
