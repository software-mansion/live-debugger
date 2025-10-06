defmodule LiveDebuggerDev.LiveViews.Stream do
  use DevWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_id, 0)
     |> assign(:another_items_id, 0)
     |> stream(:items, [])
     |> stream(:another_items, [])}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <h1>Stream Example</h1>

      <div style="margin-bottom: 1rem;">
        <button phx-click="create_item">➕ Create Item</button>
        <button phx-click="update_item">♻️ Update Last Item</button>
        <button phx-click="insert_many">📦 Insert Many</button>
        <button phx-click="delete_item">🗑️ Delete Last</button>
        <button phx-click="create_another_item">🌟 Create Another Item</button>
      </div>

      <hr />

      <h2>Items Stream:</h2>
      <ul id="item-list" phx-update="stream">
        <li :for={{id, item} <- @streams.items} id={id}>
          <strong>ID:</strong> {item.id}, <strong>Number:</strong> {item.number}
        </li>
      </ul>

      <hr />

      <h2>Another Items Stream:</h2>
      <ul id="another-items-list" phx-update="stream">
        <li :for={{id, item} <- @streams.another_items} id={id}>
          ✅ Item #{item.id} → {item.number}
        </li>
      </ul>
    </div>
    """
  end

  @impl true
  def handle_event("create_item", _params, socket) do
    next_id = socket.assigns.current_id
    item = %{id: next_id, number: Enum.random(1..100)}

    socket =
      socket
      |> stream_insert(:items, item, at: -1)
      |> assign(:current_id, next_id + 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_item", _params, socket) do
    id_to_update = socket.assigns.current_id - 1

    if id_to_update >= 0 do
      updated_item = %{id: id_to_update, number: Enum.random(1..100)}

      socket =
        socket
        |> stream_insert(:items, updated_item, at: -1, update_only: true)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("insert_many", _params, socket) do
    start_id = socket.assigns.current_id

    items =
      Enum.map(0..2, fn i ->
        %{id: start_id + i, number: Enum.random(1..100)}
      end)

    socket =
      socket
      |> stream(:items, items, at: 0)
      |> assign(:current_id, start_id + length(items))

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_item", _params, socket) do
    last_id = socket.assigns.current_id - 1

    if last_id >= 0 do
      socket =
        socket
        |> stream_delete_by_dom_id(:items, "items-#{last_id}")
        |> assign(:current_id, last_id)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("create_another_item", _params, socket) do
    next_id = socket.assigns.another_items_id
    item = %{id: next_id, number: Enum.random(1..100)}

    socket =
      socket
      |> stream_insert(:another_items, item, at: -1)
      |> assign(:another_items_id, next_id + 1)

    {:noreply, socket}
  end
end
