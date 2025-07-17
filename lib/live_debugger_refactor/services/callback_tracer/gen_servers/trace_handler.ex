defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler do
  @moduledoc """
  GenServer for handling trace data.
  """

  use GenServer

  require Logger

  alias LiveDebuggerRefactor.Utils.Callbacks, as: CallbackUtils

  @allowed_callbacks Enum.map(CallbackUtils.all_callbacks(), &elem(&1, 0))

  defguard allowed?(fun) when fun in @allowed_callbacks

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
    handle_trace(trace, n)

    {:noreply, state}
  end

  # We catch this trace to know when modules were recompiled.
  # We do not display this trace to user, so we do not have to care about order
  # We need to catch that case because tracer disconnects from modules that were recompiled
  # and we need to reapply tracing patterns to them.
  # This will be replaced in the future with a more efficient way to handle this.
  # https://github.com/software-mansion/live-debugger/issues/592
  defp handle_trace({_, _, :return_from, {Mix.Tasks.Compile.Elixir, _, _}, {:ok, _}, _}, n) do
    # TODO: Update traced modules
    dbg("Update traced modules")
    dbg(n)

    :ok
  end

  defp handle_trace({_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _}, _), do: :ok
  defp handle_trace({_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _, _}, _), do: :ok

  # We do not display this trace to user, so we do not have to care about order
  # We trace it to refresh the components tree
  # It will be replaced in the future by telemetry event added in LiveView 1.1.0
  # [:phoenix, :live_component, :destroyed]
  # https://hexdocs.pm/phoenix_live_view/1.1.0-rc.3/telemetry.html
  defp handle_trace(
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}, ts},
         n
       ) do
    dbg("Delete component")
    dbg(pid)
    dbg(cid)
    dbg(args)
    dbg(ts)
    dbg(n)

    :ok
  end

  # This handles callbacks created by user that will be displayed to user
  # It cannot be async because we care about order
  defp handle_trace({_, pid, :call, {module, fun, args}, ts}, n) when allowed?(fun) do
    dbg("Callback")
    dbg(pid)
    dbg(module)
    dbg(fun)
    dbg(args)
    dbg(ts)
    dbg(n)

    :ok
  end

  # This handles callbacks created by user that will be displayed to user
  # It cannot be async because we care about order
  defp handle_trace({_, pid, :return_from, {module, fun, _}, _, ts}, n) when allowed?(fun) do
    dbg("Callback return")
    dbg(pid)
    dbg(module)
    dbg(fun)
    dbg(ts)
    dbg(n)
    :ok
  end

  # This handles callbacks created by user that will be displayed to user
  # It cannot be async because we care about order
  defp handle_trace({_, pid, :exception_from, {module, fun, _}, _, ts}, n) when allowed?(fun) do
    dbg("Callback exception")
    dbg(pid)
    dbg(module)
    dbg(fun)
    dbg(ts)
    dbg(n)

    :ok
  end

  defp handle_trace(trace, n) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")
    n
  end
end
