defmodule LiveDebuggerDev.LiveViews.MemoryExplosion do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents.ManyAssigns

  @event_interval_ms 140
  @list_size 550
  @payload_bytes 8_000
  @burst_per_interval 2

  @impl true
  def mount(params, _session, socket) do
    {profile, profile_defaults} = profile_defaults(params["profile"] || "medium")
    interval_ms = int_param(params, "interval_ms", profile_defaults.interval_ms, 10, 10_000)
    list_size = int_param(params, "list_size", profile_defaults.list_size, 100, 5_000)
    payload_bytes = int_param(params, "payload_bytes", profile_defaults.payload_bytes, 1_000, 50_000)
    burst = int_param(params, "burst", profile_defaults.burst, 1, 20)
    heavy_items = build_heavy_items(list_size, payload_bytes)

    socket =
      socket
      |> assign(:running?, false)
      |> assign(:profile, profile)
      |> assign(:event_interval_ms, interval_ms)
      |> assign(:payload_bytes, payload_bytes)
      |> assign(:list_size, list_size)
      |> assign(:burst_per_interval, burst)
      |> assign(:tick_count, 0)
      |> assign(:clock_1, 0)
      |> assign(:clock_2, 0)
      |> assign(:clock_3, 0)
      |> assign(:clock_4, 0)
      |> assign(:clock_5, 0)
      |> assign(:clock_6, 0)
      |> assign(:heavy_items, heavy_items)

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6 space-y-4">
      <.box title="Memory Explosion Repro">
        <div class="space-y-2">
          <p>
            This view reproduces high-frequency callback churn with large assigns.
            It keeps a 500-item list in assigns and triggers `handle_event/3` about 5-6 times/sec.
          </p>
          <p>Tick count: <%= @tick_count %></p>
          <p>Profile: <%= @profile %></p>
          <p>Assign list size: <%= length(@heavy_items) %></p>
          <p>Payload complexity: <%= @payload_bytes %></p>
          <p>Burst per interval: <%= @burst_per_interval %></p>
          <p>
            Timers:
            <%= @clock_1 %>, <%= @clock_2 %>, <%= @clock_3 %>, <%= @clock_4 %>, <%= @clock_5 %>,
            <%= @clock_6 %>
          </p>
          <div class="flex gap-2">
            <.button phx-click="start" color="green">Start Spam</.button>
            <.button phx-click="stop" color="red">Stop Spam</.button>
            <.button phx-click="tick_once">Tick Once</.button>
          </div>
          <p class="text-sm">
            Quick presets:
            <a class="text-blue-600 underline" href="?profile=mild">mild</a>,
            <a class="text-blue-600 underline" href="?profile=medium">medium</a>,
            <a class="text-blue-600 underline" href="?profile=aggressive">aggressive</a>
          </p>
        </div>
      </.box>

      <.live_component id="memory-explosion-left" module={ManyAssigns} />
      <.live_component id="memory-explosion-right" module={ManyAssigns} />
      <div
        id="memory-explosion-spam"
        phx-hook="MemoryExplosionSpam"
        data-running={to_string(@running?)}
        data-interval={Integer.to_string(@event_interval_ms)}
      >
      </div>

      <div class="hidden">
        <%= for item <- @heavy_items do %>
          <span><%= item.id %></span>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("start", _params, socket) do
    {:noreply, assign(socket, :running?, true)}
  end

  def handle_event("stop", _params, socket) do
    {:noreply, assign(socket, :running?, false)}
  end

  def handle_event("tick_once", _params, socket) do
    {:noreply, apply_tick(socket)}
  end

  def handle_event("tick", _params, socket) do
    if socket.assigns.running? do
      socket =
        Enum.reduce(1..socket.assigns.burst_per_interval, socket, fn _, acc ->
          apply_tick(acc)
        end)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  defp apply_tick(socket) do
    tick = socket.assigns.tick_count + 1

    socket
    |> assign(:tick_count, tick)
    |> assign(:clock_1, rem(tick, 10_000))
    |> assign(:clock_2, rem(tick + 1, 10_000))
    |> assign(:clock_3, rem(tick + 2, 10_000))
    |> assign(:clock_4, rem(tick + 3, 10_000))
    |> assign(:clock_5, rem(tick + 4, 10_000))
    |> assign(:clock_6, rem(tick + 5, 10_000))
    |> assign(:heavy_items, rebuild_items(tick, socket.assigns.list_size, socket.assigns.payload_bytes))
  end

  defp rebuild_items(tick, list_size, payload_bytes) do
    build_heavy_items(list_size, payload_bytes, tick)
  end

  defp build_heavy_items(size, payload_bytes, tick \\ 0) do
    Enum.map(1..size, fn id ->
      payload = build_heap_payload(id, payload_bytes, tick)

      %{
        id: id,
        counter: tick,
        meta: %{
          bucket: rem(id, 10),
          tags: ["alpha", "beta", "gamma"],
          payload: payload
        }
      }
    end)
  end

  defp build_heap_payload(id, payload_complexity, tick) do
    # Intentionally avoids large binaries; creates nested terms that live on process heap.
    inner_size = max(div(payload_complexity, 100), 10)
    outer_size = max(div(payload_complexity, 250), 6)

    nested =
      Enum.map(1..outer_size, fn outer ->
        values =
          Enum.map(1..inner_size, fn inner ->
            rem(id * 1_000_003 + tick * 97 + outer * 31 + inner, 1_000_000)
          end)

        %{
          idx: outer,
          values: values,
          tuple: {outer, Enum.sum(values), List.first(values), List.last(values)},
          flags: [odd?: rem(outer, 2) == 1, hot?: rem(tick + outer, 7) == 0]
        }
      end)

    %{
      nested: nested,
      checksum: Enum.reduce(nested, 0, fn %{tuple: {_, a, b, c}}, acc -> acc + a + b + c end)
    }
  end

  defp int_param(params, key, default, lower_bound, upper_bound) do
    case Integer.parse(Map.get(params, key, "")) do
      {value, ""} -> value |> Kernel.max(lower_bound) |> Kernel.min(upper_bound)
      _ -> default
    end
  end

  defp profile_defaults("mild"),
    do: {"mild", %{interval_ms: 180, list_size: 450, payload_bytes: 6_000, burst: 1}}

  defp profile_defaults("aggressive"),
    do: {"aggressive", %{interval_ms: 80, list_size: 900, payload_bytes: 14_000, burst: 3}}

  defp profile_defaults(_),
    do: {"medium", %{interval_ms: @event_interval_ms, list_size: @list_size, payload_bytes: @payload_bytes, burst: @burst_per_interval}}
end
