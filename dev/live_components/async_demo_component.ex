defmodule LiveDebuggerDev.LiveComponents.AsyncDemoComponent do
  use DevWeb, :live_component

  def mount(socket) do
    socket =
      socket
      |> assign(component_start_async_result: nil)
      |> assign(component_async_data1: nil)
      |> assign(component_async_data2: nil)
      |> assign(component_start_async_loading: false)
      |> assign(component_cancelable_result: nil)
      |> assign(component_cancelable_loading: false)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.box title="Async Demo [LiveComponent]" color="teal">
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <.button
                id="component-start-async-button"
                phx-click="component_trigger_start_async"
                phx-target={@myself}
                color="blue"
              >
                Trigger start_async
              </.button>
              <%= if @component_start_async_loading do %>
                <span class="text-yellow-500">Loading...</span>
              <% else %>
                <span class="text-xl">
                  Result: <%= inspect(@component_start_async_result) %>
                </span>
              <% end %>
            </div>
          </div>

          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <.button
                id="component-assign-async-button"
                phx-click="component_trigger_assign_async"
                phx-target={@myself}
                color="green"
              >
                Trigger assign_async
              </.button>
              <%= if @component_async_data1 do %>
                <.async_result :let={data} assign={@component_async_data1}>
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
                  Data: <%= inspect(@component_async_data1) %>
                </span>
              <% end %>
            </div>
          </div>

          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <.button
                id="component-start-async-button-no-render"
                phx-click="component_trigger_start_async_no_render"
                phx-target={@myself}
                color="blue"
              >
                Trigger start_async (no render)
              </.button>
            </div>
          </div>

          <div class="flex flex-col gap-2">
            <div class="flex items-center gap-2">
              <.button
                id="component-start-cancelable-async-button"
                phx-click="component_trigger_cancelable_async"
                phx-target={@myself}
                color="orange"
              >
                Trigger cancelable async
              </.button>
              <%= if @component_cancelable_loading do %>
                <.button
                  id="component-cancel-async-button"
                  phx-click="component_cancel_async_job"
                  phx-target={@myself}
                  color="red"
                >
                  Cancel
                </.button>
                <span class="text-yellow-500">Loading (can be cancelled)...</span>
              <% else %>
                <span class="text-xl">
                  Result: <%= inspect(@component_cancelable_result) %>
                </span>
              <% end %>
            </div>
          </div>
        </div>
      </.box>
    </div>
    """
  end

  def handle_event("component_trigger_start_async", _params, socket) do
    socket =
      socket
      |> assign(component_start_async_loading: true)
      |> start_async(:component_fetch_data, fn ->
        Process.sleep(5000)
        {:ok, "Component data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("component_trigger_assign_async", _params, socket) do
    socket =
      assign_async(socket, [:component_async_data1, :component_async_data2], fn ->
        Process.sleep(5000)

        {:ok,
         %{
           component_async_data1: "Component async data1 loaded at #{DateTime.utc_now()}",
           component_async_data2: "Component async data2 loaded at #{DateTime.utc_now()}"
         }}
      end)

    {:noreply, socket}
  end

  def handle_event("component_trigger_start_async_no_render", _params, socket) do
    socket =
      socket
      |> start_async(:component_fetch_data_no_render, fn ->
        Process.sleep(5000)
        {:ok, "Component data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("component_trigger_cancelable_async", _params, socket) do
    socket =
      socket
      |> assign(component_cancelable_loading: true)
      |> assign(component_cancelable_result: nil)
      |> start_async(:component_cancelable_fetch, fn ->
        Process.sleep(10000)
        {:ok, "Component cancelable data fetched at #{DateTime.utc_now()}"}
      end)

    {:noreply, socket}
  end

  def handle_event("component_cancel_async_job", _params, socket) do
    socket =
      socket
      |> cancel_async(:component_cancelable_fetch)
      |> assign(component_cancelable_loading: false)
      |> assign(component_cancelable_result: "Cancelled by user")

    {:noreply, socket}
  end

  def handle_async(:component_fetch_data, {:ok, result}, socket) do
    socket =
      socket
      |> assign(component_start_async_result: result)
      |> assign(component_start_async_loading: false)

    {:noreply, socket}
  end

  def handle_async(:component_fetch_data, {:exit, reason}, socket) do
    socket =
      socket
      |> assign(component_start_async_result: "Error: #{inspect(reason)}")
      |> assign(component_start_async_loading: false)

    {:noreply, socket}
  end

  def handle_async(:component_fetch_data_no_render, _, socket) do
    {:noreply, socket}
  end

  def handle_async(:component_cancelable_fetch, {:ok, result}, socket) do
    socket =
      socket
      |> assign(component_cancelable_result: result)
      |> assign(component_cancelable_loading: false)

    {:noreply, socket}
  end

  def handle_async(:component_cancelable_fetch, {:exit, reason}, socket) do
    socket =
      socket
      |> assign(component_cancelable_result: "Cancelled: #{inspect(reason)}")
      |> assign(component_cancelable_loading: false)

    {:noreply, socket}
  end
end
