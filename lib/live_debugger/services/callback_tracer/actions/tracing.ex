defmodule LiveDebugger.Services.CallbackTracer.Actions.Tracing do
  @moduledoc """
  This module provides actions for tracing.

  Tracing uses `:dbg` in `:port` mode with the `:ip` trace port driver:
  the BEAM-side producer encodes events in C and writes them to a local
  TCP socket buffered in kernel space, decoupling traced processes from
  the consumer (the `:dbg.trace_client` process running `Tracer.handle_trace/2`).
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

  @default_queue_size 5

  @doc """
  Sets up tracing and monitors recompilation in a single pass.
  Fetches and processes the module list only once for efficiency.
  """
  @spec setup_tracing_with_monitoring!(TracingManager.state()) :: TracingManager.state()
  def setup_tracing_with_monitoring!(state) do
    last_id = TraceQueries.get_last_trace_id()

    if Map.get(state, :dbg_pid) do
      Dbg.stop()
    end

    bound_port = pick_bound_port()
    queue_size = Application.get_env(:live_debugger, :tracer_ip_queue_size, @default_queue_size)
    port_fun = Dbg.trace_port(:ip, {bound_port, queue_size})

    case Dbg.tracer(:port, port_fun) do
      {:ok, _tracer_port_pid} ->
        client_pid =
          Dbg.trace_client(
            :ip,
            {~c"localhost", bound_port},
            {&Tracer.handle_trace/2, {:init, last_id - 1}}
          )

        Process.monitor(client_pid)

        Dbg.process([:c, :timestamp, :procs])

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

        %{state | dbg_pid: client_pid}

      {:error, error} ->
        raise "Couldn't start tracer: #{inspect(error)}"
    end
  end

  # Open a transient listener on port 0 to discover an available port number,
  # then close it before handing the port back to the IP trace driver. This is
  # racy in principle (another process could grab the port in the gap), but in
  # practice the window is sub-millisecond and the alternative — a fixed port
  # — collides on multi-instance setups.
  @spec pick_bound_port() :: :inet.port_number()
  defp pick_bound_port() do
    case Application.get_env(:live_debugger, :tracer_ip_port) do
      port when is_integer(port) and port > 0 ->
        port

      _ ->
        {:ok, sock} = :gen_tcp.listen(0, [:binary, ip: {127, 0, 0, 1}])
        {:ok, port} = :inet.port(sock)
        :gen_tcp.close(sock)
        port
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
