defmodule LiveDebuggerDev.LiveViews.AsyncDemo do
  use DevWeb, :live_view

  @short_load_time 500
  @long_load_time 5000

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(start_async_result: nil)
      |> assign(async_data1: nil)
      |> assign(async_data2: nil)
      |> assign(start_async_loading: false)
      |> assign(cancelable_result: nil)
      |> assign(cancelable_loading: false)
      |> assign(long_load: false)
      |> assign(short_load_time: @short_load_time)
      |> assign(long_load_time: @long_load_time)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.box title="Async Demo [LiveView]" color="purple">
      <div class="flex items-center gap-2 mb-4 p-2 bg-gray-100 rounded">
        <input
          type="checkbox"
          id="long-load-toggle"
          phx-click="toggle_long_load"
          checked={@long_load}
        />
        <label for="long-load-toggle" class="cursor-pointer">
          Long load (<%= @long_load_time %>ms) - currently: <%= if @long_load,
            do: "ON (#{@long_load_time}ms)",
            else: "OFF (#{@short_load_time}ms)" %>
        </label>
      </div>
      <div class="flex flex-col gap-4 mb-4">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <.button id="start-async-button" phx-click="trigger_start_async" color="blue">
              Trigger start_async
            </.button>
            <%= if @start_async_loading do %>
              <span class="text-yellow-500">Loading...</span>
            <% else %>
              <span class="text-xl">
                Result: <%= inspect(@start_async_result) %>
              </span>
            <% end %>
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <.button id="assign-async-button" phx-click="trigger_assign_async" color="green">
              Trigger assign_async
            </.button>
            <%= if @async_data1 do %>
              <.async_result :let={data} assign={@async_data1}>
                <:loading>
                  <span class="text-yellow-500">Loading async data...</span>
                </:loading>
                <:failed :let={_reason}>
                  <span class="text-red-500">Failed to load</span>
                </:failed>
                <span class="text-xl">
                  Data: <%= inspect(data) %>
                </span>
              </.async_result>
            <% else %>
              <span class="text-xl">
                Data: <%= inspect(@async_data1) %>
              </span>
            <% end %>
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <.button
              id="start-async-button-no-render"
              phx-click="trigger_start_async_no_render"
              color="blue"
            >
              Trigger start_async (no render)
            </.button>
          </div>
        </div>

        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <.button
              id="start-cancelable-async-button"
              phx-click="trigger_cancelable_async"
              color="orange"
            >
              Trigger cancelable async
            </.button>
            <%= if @cancelable_loading do %>
              <.button id="cancel-async-button" phx-click="cancel_async_job" color="red">
                Cancel
              </.button>
              <span class="text-yellow-500">Loading (can be cancelled)...</span>
            <% else %>
              <span class="text-xl">
                Result: <%= inspect(@cancelable_result) %>
              </span>
            <% end %>
          </div>
        </div>
      </div>
      <.live_component
        module={LiveDebuggerDev.LiveComponents.AsyncDemoComponent}
        id="async-demo-component"
      />
    </.box>
    """
  end

  def handle_event("toggle_long_load", _params, socket) do
    {:noreply, update(socket, :long_load, &(not &1))}
  end

  def handle_event("trigger_start_async", _params, socket) do
    sleep_time = get_sleep_time(socket)

    socket =
      socket
      |> assign(start_async_loading: true)
      |> start_async(:fetch_data, fn ->
        Process.sleep(sleep_time)
        {:ok, "Data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("trigger_assign_async", _params, socket) do
    sleep_time = get_sleep_time(socket)

    socket =
      assign_async(socket, [:async_data1, :async_data2], fn ->
        Process.sleep(sleep_time)

        {:ok,
         %{
           async_data1: "Async data1 loaded at #{DateTime.utc_now()}",
           async_data2: "Async data2 loaded at #{DateTime.utc_now()}"
         }}
      end)

    {:noreply, socket}
  end

  def handle_event("trigger_start_async_no_render", _params, socket) do
    sleep_time = get_sleep_time(socket)

    socket =
      socket
      |> start_async(:fetch_data_no_render, fn ->
        Process.sleep(sleep_time)
        {:ok, "Data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("trigger_cancelable_async", _params, socket) do
    sleep_time = get_sleep_time(socket)

    socket =
      socket
      |> assign(cancelable_loading: true)
      |> assign(cancelable_result: nil)
      |> start_async(:cancelable_fetch, fn ->
        Process.sleep(sleep_time)
        {:ok, "Cancelable data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("cancel_async_job", _params, socket) do
    socket =
      socket
      |> cancel_async(:cancelable_fetch)
      |> assign(cancelable_loading: false)
      |> assign(cancelable_result: "Cancelled by user")

    {:noreply, socket}
  end

  def handle_async(:fetch_data, {:ok, result}, socket) do
    socket =
      socket
      |> assign(start_async_result: result)
      |> assign(start_async_loading: false)

    {:noreply, socket}
  end

  def handle_async(:fetch_data, {:exit, reason}, socket) do
    socket =
      socket
      |> assign(start_async_result: "Error: #{inspect(reason)}")
      |> assign(start_async_loading: false)

    {:noreply, socket}
  end

  def handle_async(:fetch_data_no_render, _, socket) do
    {:noreply, socket}
  end

  def handle_async(:cancelable_fetch, {:ok, result}, socket) do
    socket =
      socket
      |> assign(cancelable_result: result)
      |> assign(cancelable_loading: false)

    {:noreply, socket}
  end

  def handle_async(:cancelable_fetch, {:exit, reason}, socket) do
    socket =
      socket
      |> assign(cancelable_result: "Cancelled: #{inspect(reason)}")
      |> assign(cancelable_loading: false)

    {:noreply, socket}
  end

  defp get_sleep_time(socket) do
    if socket.assigns.long_load, do: @long_load_time, else: @short_load_time
  end
end
