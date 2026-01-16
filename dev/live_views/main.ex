defmodule LiveDebuggerDev.LiveViews.Main do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents

  @long_text """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
    Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.
  """

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(counter: 0)
      |> assign(counter_slow: 0)
      |> assign(counter_very_slow: 0)
      |> assign(large_assign: "")
      |> assign(datetime: nil)
      |> assign(name: random_name())
      |> assign(pid: self())
      |> assign(ref: :ets.new(:dev_main_table, []))
      |> assign(func: fn a -> {:ok, a} end)
      |> assign(single_element_list: [%Phoenix.LiveComponent.CID{cid: 1}])
      |> assign(list: [%Phoenix.LiveComponent.CID{cid: 1}, %Phoenix.LiveComponent.CID{cid: 2}])
      |> assign(other_list: [b: %{d: 4, b: 3}, a: %{g: 1, i: 2}, e: {3, 8, 2}, c: [9, 8, 7]])
      |> assign(
        cid_map: %{
          %Phoenix.LiveComponent.CID{cid: 1} => "1",
          %Phoenix.LiveComponent.CID{cid: 2} => DateTime.utc_now(),
          DateTime.utc_now() => "DateTime"
        }
      )
      |> assign(long_assign: @long_text)
      |> assign(deep_assign: %{b: %{c: %{d: %{e: %{f: %{g: "deep value"}}}}}})
      |> assign(message: nil)

    {:ok, socket, temporary_assigns: [message: nil]}
  end

  def render(assigns) do
    ~H"""
    <.box title="Main [LiveView]" color="blue">
      <div id="chat-messages">
        <p :if={@message != nil}>
          <span><%= @message.name %>:</span> <%= @message.text %>
        </p>
      </div>
      <div class="flex flex-col gap-2">
        <div class="flex items-center gap-2">
          <.button id="append-message" phx-click="append-message" color="green">
            Append message
          </.button>
        </div>
        <div class="flex items-center gap-2">
          <.button id="increment-button" phx-click="increment" color="blue">
            Increment
          </.button>
          <span class="text-xl"><%= @counter %></span>
        </div>
        <div class="flex items-center gap-2">
          <.button id="slow-increment-button" phx-click="slow-increment" color="blue">
            Slow Increment
          </.button>
          <span class="text-xl"><%= @counter_slow %></span>
        </div>
        <div class="flex items-center gap-2">
          <.button id="very-slow-increment-button" phx-click="very-slow-increment" color="blue">
            Very Slow Increment
          </.button>
          <span class="text-xl"><%= @counter_very_slow %></span>
        </div>
        <div class="flex items-center gap-2">
          <.button id="large-assign-increment-button" phx-click="large-assign-increment" color="blue">
            Large Assign Increment
          </.button>
          <span class="text-xl"><%= String.length(@large_assign) %></span>
          <span class="hidden"><%= @large_assign %></span>
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
        <.live_component id="crash" module={LiveComponents.Crash} />
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

  def handle_event("append-message", _, socket) do
    {:noreply, assign(socket, :message, %{name: "message name", text: "some text"})}
  end

  def handle_event("increment", _, socket) do
    {:noreply, update(socket, :counter, &(&1 + 1))}
  end

  def handle_event("slow-increment", _, socket) do
    Process.sleep(400)
    {:noreply, update(socket, :counter_slow, &(&1 + 1))}
  end

  def handle_event("very-slow-increment", _, socket) do
    Process.sleep(1100)
    {:noreply, update(socket, :counter_very_slow, &(&1 + 1))}
  end

  def handle_event("large-assign-increment", _, socket) do
    {:noreply, assign(socket, large_assign: socket.assigns.large_assign <> @long_text)}
  end

  def handle_event("change_name", _, socket) do
    {:noreply, assign(socket, name: random_name())}
  end

  def handle_info({:new_datetime, datetime}, socket) do
    {:noreply, assign(socket, datetime: datetime)}
  end

  def handle_info(:increment, socket) do
    {:noreply, assign(socket, counter: socket.assigns.counter + 1)}
  end

  defp random_name() do
    Enum.random(["Alice", "Bob", "Charlie", "David", "Eve"])
  end
end
