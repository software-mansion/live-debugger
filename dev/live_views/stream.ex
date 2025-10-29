defmodule LiveDebuggerDev.LiveViews.Stream do
  use DevWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream_configure(:items, dom_id: &"item-#{&1.id}")
      |> stream_configure(:another_items, dom_id: &"another-#{&1.id}")
      |> assign(:current_id, 0)
      |> assign(:another_items_id, 0)
      # |> assign(:async_loaded?, false)
      |> stream(:items, [])
      |> stream(:another_items, [])

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.box title="Items Stream options">
      <.button phx-click="create_item">Create Item</.button>
      <.button phx-click="update_item">Update Last Item</.button>
      <.button phx-click="insert_many">Insert Many (Reverse Order)</.button>
      <.button phx-click="insert_at_index">Insert At Index 4</.button>
      <.button phx-click="delete_item">Delete Last</.button>
      <.button phx-click="reset_items">Reset Stream</.button>
      <.button phx-click="limit_stream">Limit Stream (5)</.button>
      <%!-- <.button phx-click="async_load">Async Load Items</.button> --%>
      <.button phx-click="delete_both_last">Delete Last From Both Streams</.button>
    </.box>

    <hr />

    <.box title="Items Stream">
      <ul id="item-list" phx-update="stream">
        <li :for={{id, item} <- @streams.items} id={id}>
          <strong>ID:</strong> {item.id}, <strong>Number:</strong> {item.number}
          <button phx-click="delete_by_dom_id" phx-value-id={id}>X</button>
        </li>
      </ul>
    </.box>

    <hr />

    <.box title="Another Items stream options">
      <.button phx-click="create_another_item">Create Another Item</.button>
    </.box>

    <.box title="Another Items Stream">
      <ul id="another-items-list" phx-update="stream">
        <li :for={{id, item} <- @streams.another_items} id={id}>
          <strong>{item.id}</strong> ->{item.number}
        </li>
      </ul>
    </.box>

    <hr />
    """
  end

  @impl true
  def handle_event("create_item", _params, socket) do
    next_id = socket.assigns.current_id
    item = %{id: next_id, number: Enum.random(1..1000)}

    socket =
      socket
      |> stream_insert(:items, item, at: 0)
      |> assign(:current_id, next_id + 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("update_item", _params, socket) do
    id_to_update = socket.assigns.current_id - 1

    if id_to_update >= 0 do
      updated_item = %{id: id_to_update, number: Enum.random(1001..2000)}

      socket =
        socket
        |> stream_insert(:items, updated_item, update_only: true)

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
        %{id: start_id + i, number: Enum.random(1..99)}
      end)

    socket =
      socket
      |> stream(:items, Enum.reverse(items), at: -1)
      |> assign(:current_id, start_id + length(items))

    {:noreply, socket}
  end

  @impl true
  def handle_event("insert_at_index", _params, socket) do
    next_id = socket.assigns.current_id
    item = %{id: next_id, number: 9999}

    socket =
      socket
      |> stream_insert(:items, item, at: 4)
      |> assign(:current_id, next_id + 1)

    {:noreply, socket}
  end

  @impl true
  def handle_event("delete_item", _params, socket) do
    last_id = socket.assigns.current_id - 1

    if last_id >= 0 do
      socket =
        socket
        |> stream_delete(:items, %{id: last_id})
        |> assign(:current_id, last_id)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("delete_by_dom_id", %{"id" => dom_id}, socket) do
    socket = stream_delete_by_dom_id(socket, :items, dom_id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("reset_items", _params, socket) do
    socket =
      socket
      |> stream(:items, [], reset: true)
      |> assign(:current_id, 0)

    {:noreply, socket}
  end

  # @impl true
  # def handle_event("limit_stream", _params, socket) do
  #   next_id = socket.assigns.current_id
  #   item = %{id: next_id, number: Enum.random(1..100)}

  #   socket =
  #     socket
  #     |> stream_insert(:items, item, at: -1, limit: -5)
  #     |> assign(:current_id, next_id + 1)

  #   {:noreply, socket}
  # end

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

  # @impl true
  # def handle_event("async_load", _params, socket) do
  #   socket =
  #     socket
  #     |> assign(:async_loaded?, false)
  #     |> stream_async(:items, fn ->
  #       Process.sleep(1000)
  #       items = Enum.map(0..9, fn i -> %{id: i, number: Enum.random(1..500)} end)
  #       {:ok, items, reset: true}
  #     end)

  #   {:noreply, socket}
  # end

  # @impl true
  # def handle_info({:async_result, :items, {:ok, _}}, socket) do
  #   {:noreply, assign(socket, :async_loaded?, true)}
  # end

  @impl true
  def handle_event("delete_both_last", _params, socket) do
    last_item_id = socket.assigns.current_id - 1
    last_another_id = socket.assigns.another_items_id - 1

    socket =
      socket
      |> then(fn s ->
        if last_item_id >= 0 do
          stream_delete(s, :items, %{id: last_item_id})
        else
          s
        end
      end)
      |> then(fn s ->
        if last_another_id >= 0 do
          stream_delete(s, :another_items, %{id: last_another_id})
        else
          s
        end
      end)
      |> assign(:current_id, max(last_item_id, 0))
      |> assign(:another_items_id, max(last_another_id, 0))

    {:noreply, socket}
  end
end
