defmodule LiveDebugger.Services.CallbackTracer.Actions.Trace do
  @moduledoc """
  This module provides actions for traces.
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.API.LiveViewDebug

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebugger.Services.CallbackTracer.Events.TraceErrored

  @spec create_trace(
          n :: non_neg_integer(),
          module :: module(),
          fun :: atom(),
          args :: list(),
          pid :: pid(),
          timestamp :: :erlang.timestamp()
        ) :: {:ok, Trace.t()} | {:error, term()}
  def create_trace(n, module, fun, args, pid, timestamp) do
    trace = Trace.new(n, module, fun, args, pid, timestamp)

    case trace.transport_pid do
      nil ->
        {:error, "Transport PID is nil"}

      _ ->
        {:ok, trace}
    end
  end

  @spec create_delete_component_trace(
          n :: non_neg_integer(),
          args :: list(),
          pid :: pid(),
          cid :: String.t(),
          timestamp :: :erlang.timestamp()
        ) :: {:ok, Trace.t()} | {:error, term()}
  def create_delete_component_trace(n, args, pid, cid, timestamp) do
    pid
    |> LiveViewDebug.socket()
    |> case do
      {:ok, %{id: socket_id, transport_pid: t_pid}} when is_pid(t_pid) ->
        trace =
          Trace.new(
            n,
            Phoenix.LiveView.Diff,
            :delete_component,
            args,
            pid,
            timestamp,
            socket_id: socket_id,
            transport_pid: t_pid,
            cid: %Phoenix.LiveComponent.CID{cid: cid}
          )

        {:ok, trace}

      _ ->
        {:error, "Could not get socket"}
    end
  end

  @spec update_trace(Trace.t(), map()) :: {:ok, Trace.t()}
  def update_trace(%Trace{} = trace, params) do
    {:ok, Map.merge(trace, params)}
  end

  @spec persist_trace(Trace.t()) :: {:ok, reference()} | {:error, term()}
  def persist_trace(%Trace{pid: pid} = trace) do
    with ref when is_reference(ref) <- TracesStorage.get_table(pid),
         true <- TracesStorage.insert!(ref, trace) do
      {:ok, ref}
    else
      _ ->
        {:error, "Could not persist trace"}
    end
  end

  @spec persist_trace(Trace.t(), reference()) :: {:ok, reference()}
  def persist_trace(%Trace{} = trace, ref) do
    TracesStorage.insert!(ref, trace)

    {:ok, ref}
  end

  @spec publish_trace(Trace.t(), reference() | nil) :: :ok | {:error, term()}
  def publish_trace(%Trace{pid: pid} = trace, ref \\ nil) do
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
      arity: trace.arity,
      pid: trace.pid,
      cid: trace.cid,
      transport_pid: trace.transport_pid
    }
  end

  defp get_event(%Trace{type: :return_from} = trace, ref) do
    %TraceReturned{
      trace_id: trace.id,
      ets_ref: ref,
      module: trace.module,
      function: trace.function,
      arity: trace.arity,
      pid: trace.pid,
      cid: trace.cid,
      transport_pid: trace.transport_pid
    }
  end

  defp get_event(%Trace{type: :exception_from} = trace, ref) do
    %TraceErrored{
      trace_id: trace.id,
      ets_ref: ref,
      module: trace.module,
      function: trace.function,
      arity: trace.arity,
      pid: trace.pid,
      cid: trace.cid,
      transport_pid: trace.transport_pid
    }
  end
end
