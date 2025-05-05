defmodule LiveDebuggerDev.LiveViews.Main do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(counter: 0)
      |> assign(counter_slow: 0)
      |> assign(counter_very_slow: 0)
      |> assign(datetime: nil)
      |> assign(name: random_name())
      |> assign(single_element_list: [%Phoenix.LiveComponent.CID{cid: 1}])
      |> assign(list: [%Phoenix.LiveComponent.CID{cid: 1}, %Phoenix.LiveComponent.CID{cid: 2}])
      |> assign(
        long_assign:
          "flex items-center gap-2 flex grow flex-col xl:flex-row flex items-center gap-2 flex grow flex-col xl:flex-row gap-4 xl:gap-8 p-8 overflow-y-auto xl:overflow-y-hidden max-w-screen-2xl mx-auto"
      )

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.box title="Main [LiveView]" color="blue">
      <div class="flex flex-col gap-2">
        <div class="flex items-center gap-2">
          <.button id="increment-button" phx-click="increment" color="blue">
            Increment
          </.button>
          <span class="text-xl"><%= @counter %></span>
        </div>
        <div class="flex items-center gap-2">
          <.button phx-click="slow-increment" color="blue">
            Slow Increment
          </.button>
          <span class="text-xl"><%= @counter_slow %></span>
        </div>
        <div class="flex items-center gap-2">
          <.button phx-click="very-slow-increment" color="blue">
            Very Slow Increment
          </.button>
          <span class="text-xl"><%= @counter_very_slow %></span>
        </div>
        <div class="flex items-center gap-1">
          <.button id="update-button" phx-click="change_name" color="red">
            Update
          </.button>
          <div>
            variable shared with <span class="text-red-500">first component</span> - favorite person:
          </div>
          <div class="italic"><%= @name %></div>
        </div>
        <div>
          Message from <span class="text-green-500">second component</span> <%= @datetime %>
        </div>

        <.live_component id="many_assigns" module={LiveComponents.ManyAssigns} />
        <.live_component id="name_outer" name={@name} module={LiveComponents.Name} />
        <.live_component id="send_outer" module={LiveComponents.Send}>
          <.live_component id="name_inner" name={@name} module={LiveComponents.Name} />
          <.live_component id="long_name" module={LiveComponents.LiveComponentWithVeryVeryLongName} />
        </.live_component>
        <.live_component id="conditional" module={LiveComponents.Conditional}>
          <.live_component
            id="conditional-many-assigns"
            module={LiveDebuggerDev.LiveComponents.ManyAssigns}
          />
        </.live_component>

        <.live_component id="conditional-rec-1" module={LiveComponents.Conditional}>
          <.live_component id="conditional-rec-2" module={LiveComponents.Conditional}>
            <.live_component id="conditional-rec-3" module={LiveComponents.Conditional}>
              <.live_component
                id="conditional-many-assigns-rec"
                module={LiveDebuggerDev.LiveComponents.ManyAssigns}
              />
            </.live_component>
          </.live_component>
        </.live_component>
        <.live_component id="recursive" counter={5} module={LiveComponents.Recursive} />
      </div>
    </.box>
    """
  end

  def handle_event("increment", _, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def handle_event("slow-increment", _, socket) do
    Process.sleep(400)
    {:noreply, update(socket, :counter_slow, &(&1 + 1))}
  end

  def handle_event("very-slow-increment", _, socket) do
    Process.sleep(2500)
    {:noreply, update(socket, :counter_very_slow, &(&1 + 1))}
  end

  def handle_event("change_name", _, socket) do
    {:noreply, assign(socket, name: random_name())}
  end

  def handle_info({:new_datetime, datetime}, socket) do
    {:noreply, assign(socket, datetime: datetime)}
  end

  defp random_name() do
    Enum.random(["Alice", "Bob", "Charlie", "David", "Eve"])
  end
end
