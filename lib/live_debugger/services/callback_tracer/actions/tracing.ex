defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.
  """
  require Logger

  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager
  alias LiveDebugger.Services.CallbackTracer.Queries.Callbacks, as: CallbackQueries
  alias LiveDebugger.Services.CallbackTracer.Queries.Paths, as: PathQueries
  alias LiveDebugger.Services.CallbackTracer.Queries.Traces, as: TraceQueries
  alias LiveDebugger.Services.CallbackTracer.Process.Tracer
  alias LiveDebugger.API.System.FileSystem, as: FileSystemAPI
  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Modules, as: UtilsModules
  alias LiveDebugger.API.System.Dbg

  @live_view_vsn Application.spec(:phoenix_live_view, :vsn) |> to_string()

  @spec setup_tracing!(TracingManager.state()) :: pid() | nil
  def setup_tracing!(state) do
    last_id = TraceQueries.get_last_trace_id()

    case Dbg.tracer({&Tracer.handle_trace/2, last_id - 1}) do
      {:ok, pid} ->
        Process.monitor(pid)

        Dbg.process([:c, :timestamp, :procs])
        apply_trace_patterns()

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

  @doc """
  Starts FileSystem monitor and subscribes to it for compiled modules directories.
  When changes are detected in the monitored directories,
  process will receive `{:file_event, _pid, {path, events}}` message.
  """

  @spec monitor_recompilation() :: :ok
  def monitor_recompilation() do
    directories = PathQueries.compiled_modules_directories()
    FileSystemAPI.start_link(dirs: directories, name: :lvdbg_file_system_monitor)
    FileSystemAPI.subscribe(:lvdbg_file_system_monitor)

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

  defp apply_trace_patterns() do
    # This is not a callback created by user
    # We trace it to refresh the components tree
    # This will be replaced with telemetry event added in LiveView 1.1.0
    if not Version.match?(@live_view_vsn, ">= 1.1.0-rc.0") do
      Dbg.trace_pattern({Phoenix.LiveView.Diff, :delete_component, 2}, [])
    end

    CallbackQueries.all_callbacks()
    |> Enum.each(fn mfa ->
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:return_trace))
      Dbg.trace_pattern(mfa, Dbg.flag_to_match_spec(:exception_trace))
    end)
  end

  defp beam_file?(path) do
    String.ends_with?(path, ".beam")
  end
end
