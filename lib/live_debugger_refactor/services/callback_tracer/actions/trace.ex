defmodule LiveDebuggerRefactor.Services.CallbackTracer.Actions.Trace do
  @moduledoc """
  This module provides actions for traces.
  """

  alias LiveDebuggerRefactor.Structs.Trace
  alias LiveDebuggerRefactor.API.TracesStorage, as: TracesStorage

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebuggerRefactor.Services.CallbackTracer.Events.TraceErrored

  def create_trace(n, module, fun, args, pid, timestamp) do
    trace = Trace.new(n, module, fun, args, pid, timestamp)

    case trace.transport_pid do
      nil ->
        {:error, "Transport PID is nil"}

      _ ->
        {:ok, trace}
    end
  end

  def update_trace(%Trace{} = trace, params) do
    {:ok, Map.merge(trace, params)}
  end

  def persist_trace(%Trace{pid: pid} = trace) do
    with ref when is_reference(ref) <- TracesStorage.get_table(pid),
         true <- TracesStorage.insert!(ref, trace) do
      {:ok, ref}
    else
      _ ->
        {:error, "Could not persist trace"}
    end
  end

  def persist_trace(%Trace{} = trace, ref) do
    with true <- TracesStorage.insert!(ref, trace) do
      {:ok, ref}
    else
      _ ->
        {:error, "Could not persist trace"}
    end
  end

  def publish_trace(%Trace{pid: pid} = trace, ref) do
    trace
    |> get_event(ref)
    |> Bus.broadcast_trace!(pid)
  rescue
    err ->
      {:error, err}
  end

  defp get_event(%Trace{type: :call} = trace, ref) do
    %TraceCalled{
      trace_id: trace.id,
      ets_ref: ref,
      module: trace.module,
      function: trace.function,
      pid: trace.pid,
      cid: trace.cid
    }
  end

  defp get_event(%Trace{type: :return_from} = trace, ref) do
    %TraceReturned{
      trace_id: trace.id,
      ets_ref: ref,
      module: trace.module,
      function: trace.function,
      pid: trace.pid,
      cid: trace.cid
    }
  end

  defp get_event(%Trace{type: :exception_from} = trace, ref) do
    %TraceErrored{
      trace_id: trace.id,
      ets_ref: ref,
      module: trace.module,
      function: trace.function,
      pid: trace.pid,
      cid: trace.cid
    }
  end
end
