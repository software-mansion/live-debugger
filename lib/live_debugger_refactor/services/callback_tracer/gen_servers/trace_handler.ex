defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler do
  @moduledoc """
  GenServer for handling trace data.
  """

  use GenServer

  require Logger

  alias LiveDebuggerRefactor.Utils.Callbacks, as: CallbackUtils

  @allowed_callbacks Enum.map(CallbackUtils.all_callbacks(), &elem(&1, 0))

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
  def handle_cast(
        {:new_trace, {_, _, :return_from, {Mix.Tasks.Compile.Elixir, _, _}, {:ok, _}, _}, n},
        state
      ) do
    # TODO: Update traced modules
    dbg("Update traced modules")
    dbg([n, state])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _}, _}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, _, _, {Mix.Tasks.Compile.Elixir, _, _}, _, _}, _}, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(
        {:new_trace,
         {_, pid, _, {Phoenix.LiveView.Diff, :delete_component, [cid | _] = args}, ts}, n},
        state
      ) do
    dbg("Delete component")
    dbg([pid, cid, args, ts, n, state])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, pid, :call, {module, fun, args}, ts}, n}, state)
      when fun in @allowed_callbacks do
    dbg("Callback")
    dbg([pid, module, fun, args, ts, n, state])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, {_, pid, type, {module, fun, _}, _, ts}, n}, state)
      when fun in @allowed_callbacks and type in [:return_from, :exception_from] do
    dbg("Callback #{type}")
    dbg([pid, module, fun, ts, n, state])

    {:noreply, state}
  end

  @impl true
  def handle_cast({:new_trace, trace, _n}, state) do
    Logger.info("Ignoring unexpected trace: #{inspect(trace)}")

    {:noreply, state}
  end
end
