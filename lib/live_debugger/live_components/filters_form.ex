defmodule LiveDebugger.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:active_filters, assigns.filters)
    |> assign(:parent_id, assigns.parent_id)
    |> assign_form(assigns.filters)
    |> ok()
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :selected_filters_number, calculate_selected_filters(assigns.form))

    ~H"""
    <div id={@id <> "-wrapper"}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="w-52">
          <div class="p-4">
            <p class="font-medium mb-4">Callbacks</p>
            <div class="flex flex-col gap-3">
              <%= for {function, arity} <- get_callbacks(@node_id) do %>
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
              Clear filters
            </button>
            <.button variant="primary" size="sm" type="submit">
              Apply
              <span :if={@selected_filters_number > 0}>
                (<%= @selected_filters_number %>)
              </span>
            </.button>
          </div>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("submit", params, socket) do
    filters = update_filters(socket.assigns.active_filters, params)

    send(self(), {:filters_updated, filters})
    LiveDebugger.LiveComponents.LiveDropdown.close(socket.assigns.parent_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event("change", params, socket) do
    filters = update_filters(socket.assigns.active_filters, params)

    socket
    |> assign_form(filters)
    |> noreply()
  end

  @impl true
  def handle_event("clear", _params, socket) do
    socket
    |> assign_form([])
    |> noreply()
  end

  def assign_form(socket, filters) do
    form =
      filters
      |> Enum.reduce(%{}, fn {function, active}, acc ->
        Map.put(acc, Atom.to_string(function), active)
      end)
      |> to_form()

    assign(socket, :form, form)
  end

  def get_callbacks(node_id) do
    node_id
    |> TreeNode.type()
    |> case do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
    end
  end

  defp update_filters(active_filters, params) do
    active_filters
    |> Enum.map(fn {function, _} ->
      {function, Map.has_key?(params, Atom.to_string(function))}
    end)
  end

  defp calculate_selected_filters(form) do
    form.params
    |> Map.values()
    |> Enum.count(&Function.identity/1)
  end
end
