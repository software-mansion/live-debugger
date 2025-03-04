defmodule LiveDebugger.Services.TraceRateLimiter do
  @moduledoc """
  This module provides a rate limiter for traces.
  It should be used as a proxy between the `:dbg` tracer and LiveDebugger dashboard.
  It limits the number of traces that are sent to the dashboard.
  You can configure the number of traces and the period in which they are counted via module attributes.
  """
  use GenServer

  @traces_number 16
  @period_ms 1000
  @interval_ms div(@period_ms, @traces_number)

  def start_link(target_pid \\ self()) do
    GenServer.start_link(__MODULE__, %{target_pid: target_pid})
  end

  @impl true
  def init(%{target_pid: target_pid}) do
    schedule_processing()
    {:ok, %{target_pid: target_pid, traces: []}}
  end

  @impl true
  def handle_info(:__do_process__, state) do
    schedule_processing()

    state.traces
    |> Enum.reverse()
    |> Enum.each(fn {_key, %{last_trace: trace, counter: counter}} ->
      send(state.target_pid, {:new_trace, %{trace: trace, counter: counter}})
    end)

    {:noreply, %{state | traces: []}}
  end

  @impl true
  def handle_info({:new_trace, %{function: key} = trace}, %{traces: traces} = state) do
    updated_traces =
      traces
      |> Keyword.get(key)
      |> case do
        nil ->
          Keyword.put(traces, key, %{last_trace: trace, counter: 1})

        %{counter: counter} ->
          Keyword.put(traces, key, %{last_trace: trace, counter: counter + 1})
      end

    {:noreply, %{state | traces: updated_traces}}
  end

  defp schedule_processing() do
    Process.send_after(self(), :__do_process__, @interval_ms)
  end
end
