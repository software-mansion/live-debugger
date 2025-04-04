defmodule LiveDebugger.LiveComponents.FiltersDropdown do
  @moduledoc """
  Dropdown for filtering traces by callback.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks

  @impl true
  def update(assigns, socket) do
    default_inactive_callbacks = MapSet.new(assigns.default_inactive_callbacks || [])
    all_callbacks = get_callbacks(assigns.node_id)

    active_callbacks = get_active_callbacks(all_callbacks, default_inactive_callbacks)

    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:active_callbacks, active_callbacks)
    |> assign(:callbacks, all_callbacks)
    |> assign_form()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id={@id <> "-wrapper"}>
      <.live_component module={LiveDebugger.LiveComponents.LiveDropdown} id={@id}>
        <:button class="flex gap-2">
          <.icon name="icon-filters" class="w-4 h-4" />
          <div class="hidden @[29rem]/traces:block">Filters</div>
        </:button>
        <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
          <div class="w-52">
            <div class="p-4">
              <p class="font-medium mb-4">Callbacks</p>
              <div class="flex flex-col gap-3">
                <%= for {function, arity} <- @callbacks do %>
                  <.checkbox field={@form[function]} label={"#{function}/#{arity}"} />
                <% end %>
              </div>
            </div>
            <div class="flex py-3 px-4 border-t border-default-border items-center justify-between">
              <button
                class="text-link-primary hover:text-link-primary-hover"
                type="button"
                phx-click="clear"
                phx-target={@myself}
              >
                Clear&nbsp;filters
              </button>
              <.button variant="primary" size="sm" type="submit">
                Apply
                <span :if={MapSet.size(@active_callbacks) > 0}>
                  (<%= MapSet.size(@active_callbacks) %>)
                </span>
              </.button>
            </div>
          </div>
        </.form>
      </.live_component>
    </div>
    """
  end

  @impl true
  def handle_event("submit", params, socket) do
    filters =
      params
      |> Map.keys()
      |> Enum.map(&String.to_existing_atom/1)

    send(self(), {:filters_updated, filters})
    LiveDebugger.LiveComponents.LiveDropdown.close(socket.assigns.id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", params, socket) do
    filters =
      params
      |> Map.keys()
      |> Enum.reject(&String.starts_with?(&1, "_"))
      |> Enum.map(&String.to_existing_atom/1)

    socket
    |> assign(:active_callbacks, MapSet.new(filters))
    |> assign_form()
    |> noreply()
  end

  @impl true
  def handle_event("clear", _params, socket) do
    socket
    |> assign(:active_callbacks, MapSet.new())
    |> assign_form()
    |> noreply()
  end

  defp get_callbacks(node_id) do
    node_id
    |> TreeNode.type()
    |> case do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
    end
  end

  def assign_form(socket) do
    active_callbacks = socket.assigns.active_callbacks

    form =
      socket.assigns.callbacks
      |> Enum.reduce(%{}, fn {function, _arity}, acc ->
        active? = MapSet.member?(active_callbacks, function)
        Map.put(acc, Atom.to_string(function), active?)
      end)
      |> to_form()

    assign(socket, :form, form)
  end

  defp get_active_callbacks(all_callbacks, default_inactive_callbacks) do
    all_callbacks
    |> Enum.map(fn {function, _arity} -> function end)
    |> MapSet.new()
    |> MapSet.difference(default_inactive_callbacks)
  end
end
