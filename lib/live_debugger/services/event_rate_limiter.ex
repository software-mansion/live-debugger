defmodule LiveDebugger.Services.EventRateLimiter do
  use GenServer

  @events_number 20
  @period_ms 1000
  @interval_ms div(@period_ms, @events_number)

  def start_link(target_pid \\ self()) do
    GenServer.start_link(__MODULE__, %{target_pid: target_pid})
  end

  @impl true
  def init(%{target_pid: target_pid}) do
    schedule_processing()
    {:ok, %{target_pid: target_pid, events: []}}
  end

  @impl true
  def handle_info(:__do_process__, state) do
    schedule_processing()

    state.events
    |> Enum.reverse()
    |> Enum.each(fn {_key, %{last_event: event, counter: counter}} ->
      send(state.target_pid, {:new_trace, event, counter})
    end)

    {:noreply, %{state | events: []}}
  end

  @impl true
  def handle_info({:new_trace, %{function: key} = trace}, %{events: events} = state) do
    updated_events =
      events
      |> Keyword.get(key)
      |> case do
        nil ->
          Keyword.put(events, key, %{last_event: trace, counter: 1})

        %{counter: counter} ->
          Keyword.put(events, key, %{last_event: trace, counter: counter + 1})
      end

    {:noreply, %{state | events: updated_events}}
  end

  defp schedule_processing() do
    Process.send_after(self(), :__do_process__, @interval_ms)
  end
end
