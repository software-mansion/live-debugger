defmodule LiveDebuggerWeb.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  It sends `{:filters_updated, filters}` to the parent LiveView.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Utils.Parsers

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, assigns.node_id)
    |> assign(:active_filters, assigns.filters)
    |> assign(:default_filters, assigns.default_filters)
    |> assign_form(assigns.filters)
    |> ok()
  end

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(:selected_filters_number, calculate_selected_filters(assigns.form))
      |> assign(:errors, assigns.form.errors)

    ~H"""
    <div id={@id <> "-wrapper"}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="w-96">
          <div class="p-4">
            <p class="font-medium mb-4">Callbacks</p>
            <div class="flex flex-col gap-3">
              <%= for {function, arity} <- get_callbacks(@node_id) do %>
                <.checkbox field={@form[function]} label={"#{function}/#{arity}"} />
              <% end %>
            </div>
            <p class="font-medium mb-4 mt-6">Execution Time</p>
            <div class="mt-3 flex gap-3 items-center">
              <.input_with_units
                value_field={@form[:exec_time_min]}
                unit_field={@form[:min_unit]}
                units={Parsers.time_units()}
                min="0"
                placeholder="min"
              /> -
              <.input_with_units
                value_field={@form[:exec_time_max]}
                unit_field={@form[:max_unit]}
                min="0"
                units={Parsers.time_units()}
                placeholder="max"
              />
            </div>
            <p :for={{_, msg} <- @errors} class="mt-2 block text-error-text">
              <%= msg %>
            </p>
          </div>
          <div class="flex py-3 px-4 border-t border-default-border items-center justify-between">
            <button
              class="text-link-primary hover:text-link-primary-hover"
              type="button"
              phx-click="reset"
              phx-target={@myself}
            >
              Reset filters
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
    case update_filters(socket.assigns.active_filters, params) do
      {:ok, filters} ->
        send(self(), {:filters_updated, filters})

      _ ->
        nil
    end

    socket
    |> noreply()
  end

  @impl true
  def handle_event("change", params, socket) do
    case update_filters(socket.assigns.active_filters, params) do
      {:ok, filters} ->
        socket
        |> assign_form(filters)
        |> noreply()

      {:error, errors} ->
        socket
        |> assign(form: to_form(params, errors: errors))
        |> noreply()
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket
    |> assign_form(socket.assigns.default_filters)
    |> noreply()
  end

  def assign_form(socket, %{functions: functions, execution_time: execution_time}) do
    form =
      (functions ++ execution_time)
      |> Enum.reduce(%{}, fn {filter, value}, acc ->
        Map.put(acc, Atom.to_string(filter), value)
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
    functions =
      active_filters.functions
      |> Enum.map(fn {function, _} ->
        {function, Map.has_key?(params, Atom.to_string(function))}
      end)

    execution_time =
      active_filters.execution_time
      |> Enum.map(fn {filter, value} ->
        {filter, Map.get(params, Atom.to_string(filter), value)}
      end)

    case validate_execution_time(execution_time) do
      :ok -> {:ok, %{functions: functions, execution_time: execution_time}}
      {:error, errors} -> {:error, errors}
    end
  end

  defp validate_execution_time(execution_time) do
    min_time = execution_time[:exec_time_min]
    max_time = execution_time[:exec_time_max]
    min_time_unit = execution_time[:min_unit]
    max_time_unit = execution_time[:max_unit]

    if min_time != "" and max_time != "" and
         apply_unit_factor(min_time, min_time_unit) > apply_unit_factor(max_time, max_time_unit) do
      {:error, [exec_time_min: "min must be less than max", exec_time_max: ""]}
    else
      :ok
    end
  end

  defp apply_unit_factor(value, unit) do
    value
    |> String.to_integer()
    |> Parsers.time_to_microseconds(unit)
  end

  defp calculate_selected_filters(form) do
    callbacks =
      UtilsCallbacks.callbacks_functions()
      |> Enum.map(&Atom.to_string/1)

    form.params
    |> Enum.filter(fn {name, value} -> Enum.member?(callbacks, name) && value end)
    |> Enum.count(&Function.identity/1)
  end
end
