defmodule LiveDebuggerDev.LiveViews.Main do
  use DevWeb, :live_view

  alias LiveDebuggerDev.LiveComponents

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:counter, 0)
      |> assign(:datetime, nil)
      |> assign(name: random_name())

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="p-5">
      <.box title="Main [LiveView]" color="blue">
        <div class="flex flex-col gap-2">
          <div class="flex items-center gap-2">
            <button phx-click="increment" class="bg-blue-500 text-white py-1 px-2 rounded">
              Increment
            </button>
            <span class="text-xl">{@counter}</span>
          </div>
          <div class="flex items-center gap-1">
            <button phx-click="change_name" class="bg-red-500 text-white py-1 px-2 rounded">
              Update
            </button>
            <div>
              variable shared with <span class="text-red-500">first component</span>
              - favorite person:
            </div>
            <div class="italic">{@name}</div>
          </div>
          <div>
            Message from <span class="text-green-500">second component</span> {@datetime}
          </div>

          <.live_component
            id="many_assigns"
            {%{
            a: 1,
            b: 2,
            c: "some value",
            d: %{nested: "value"},
            e: [1, 2, 3],
            f: [a: 1, b: 2],
            g: [a: 1, b: 2, c: [1, 2, 3]],
            h: [a: 1, b: 2, c: [a: 1, b: 2]],
            i: 56,
            j: 78,
            k: 90,
            l: 12,
            m: 34,
            n: 56,
            o: "Some Long value which should be splitted to multiple lines.",
            p: 213,
            q: :abf,
            r: :cde,
            s: :fgh,
            t: :ijk,
            u: :lmn,
            v: :very_long_atom_whith_multiple_words_xxxxx_xxxxxxx_xxxxxxxxxxxxx
          }}
            module={LiveComponents.ManyAssigns}
          />
          <.live_component id="name_outer" name={@name} module={LiveComponents.Name} />
          <.live_component id="send_outer" module={LiveComponents.Send}>
            <.live_component id="name_inner" name={@name} module={LiveComponents.Name} />
            <.live_component id="long_name" module={LiveComponents.LiveComponentWithVeryVeryLongName} />
          </.live_component>
          <.live_component id="reccursive" counter={5} module={LiveComponents.Reccursive} />
        </div>
      </.box>
      <div class="mt-10">
        <.link navigate="/side" class="text-blue-500 underline">Go to side</.link>
      </div>
    </div>
    """
  end

  def handle_event("increment", _, socket) do
    {:noreply, assign(socket, :counter, socket.assigns.counter + 1)}
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
