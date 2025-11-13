defmodule LiveDebuggerDev.LiveViews.AsyncDemo do
  use DevWeb, :live_view

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(start_async_result: nil)
      |> assign(assign_async_data: nil)
      |> assign(start_async_loading: false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.box title="Async Demo [LiveView]" color="purple">
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <.button id="start-async-button" phx-click="trigger_start_async" color="blue">
              Trigger start_async (5s)
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
              Trigger assign_async (5s)
            </.button>
            <%= if @assign_async_data do %>
              <.async_result :let={data} assign={@assign_async_data}>
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
                Data: <%= inspect(@assign_async_data) %>
              </span>
            <% end %>
          </div>
        </div>
      </div>
    </.box>
    """
  end

  def handle_event("trigger_start_async", _params, socket) do
    socket =
      socket
      |> assign(start_async_loading: true)
      |> start_async(:fetch_data, fn ->
        Process.sleep(5000)
        {:ok, "Data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("trigger_assign_async", _params, socket) do
    socket =
      assign_async(socket, :assign_async_data, fn ->
        Process.sleep(5000)
        {:ok, %{assign_async_data: "Async data loaded at #{DateTime.utc_now()}"}}
      end)

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
end
