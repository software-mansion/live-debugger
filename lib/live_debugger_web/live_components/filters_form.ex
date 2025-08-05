defmodule LiveDebuggerWeb.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  It sends `{:filters_updated, filters}` to the parent LiveView.
  """
  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Utils.Callbacks, as: UtilsCallbacks
  alias LiveDebugger.Structs.TreeNode
  alias LiveDebugger.Utils.Parsers

  @doc """
  This handler is used to reset from to current active filters.
  """

  @impl true
  def update(%{reset_form?: true}, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:node_id, Map.get(assigns, :node_id, nil))
    |> assign(:active_filters, assigns.filters)
    |> assign(:default_filters, assigns.default_filters)
    |> assign(:enabled?, Map.get(assigns, :enabled?, true))
    |> assign(:revert_button_visible?, Map.get(assigns, :revert_button_visible?, false))
    |> assign_form(assigns.filters)
    |> ok()
  end

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :errors, assigns.form.errors)

    ~H"""
    <div id={@id <> "-wrapper"} class={if not @enabled?, do: "opacity-50 pointer-events-none"}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="w-full px-1">
          <.filters_group_header
            title="Callbacks"
            group_name={:functions}
            form={@form}
            default_filters={@default_filters}
            target={@myself}
          />
          <div class="flex flex-col gap-3 pl-0.5 pb-4 border-b border-default-border">
            <%= for {function, arity} <- get_callbacks(@node_id) do %>
              <.checkbox field={@form["#{function}/#{arity}"]} label={"#{function}/#{arity}"} />
            <% end %>
          </div>
          <.filters_group_header
            title="Execution Time"
            class="pt-2"
            group_name={:execution_time}
            form={@form}
            default_filters={@default_filters}
            target={@myself}
          />
          <div class="pb-5">
            <div class="flex gap-3 items-center">
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

          <div class="flex pt-4 pb-2 border-t border-default-border items-center justify-between pr-3">
            <div class="flex gap-2 items-center h-10">
              <%= if filters_changed?(@form, @active_filters) do %>
                <.button variant="primary" type="submit">
                  Apply
                </.button>
                <.button
                  :if={@revert_button_visible?}
                  variant="secondary"
                  type="button"
                  phx-click="revert"
                  phx-target={@myself}
                >
                  Revert changes
                </.button>
              <% else %>
                <.button variant="primary" type="submit" class="opacity-50 pointer-events-none">
                  Apply
                </.button>
              <% end %>
            </div>
            <button
              :if={filters_changed?(@form, @default_filters)}
              type="button"
              class="flex align-center text-link-primary hover:text-link-primary-hover"
              phx-click="reset"
              phx-target={@myself}
            >
              Reset all
            </button>
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

    {:noreply, socket}
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
        |> assign(form: to_form(params, errors: errors, id: socket.assigns.id))
        |> noreply()
    end
  end

  @impl true
  def handle_event("reset", _params, socket) do
    socket
    |> assign_form(socket.assigns.default_filters)
    |> noreply()
  end

  @impl true
  def handle_event("revert", _params, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> noreply()
  end

  @impl true
  def handle_event("reset-group", params, socket) do
    group_name = params["group"] |> String.to_existing_atom()

    socket
    |> assign_form(Map.get(socket.assigns.default_filters, group_name))
    |> noreply()
  end

  defp assign_form(socket, %{functions: functions, execution_time: execution_time}) do
    form =
      functions
      |> Map.merge(execution_time)
      |> to_form(id: socket.assigns.id)

    assign(socket, :form, form)
  end

  defp assign_form(socket, filters_map) do
    form = socket.assigns.form

    form =
      form.params
      |> Map.merge(filters_map)
      |> to_form(id: socket.assigns.id)

    assign(socket, :form, form)
  end

  def get_callbacks(nil) do
    UtilsCallbacks.all_callbacks()
  end

  def get_callbacks(node_id) do
    node_id
    |> TreeNode.type()
    |> case do
      :live_view -> UtilsCallbacks.live_view_callbacks()
      :live_component -> UtilsCallbacks.live_component_callbacks()
    end
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: "")
  attr(:group_name, :atom, required: true)
  attr(:form, :map, required: true)
  attr(:default_filters, :map, required: true)
  attr(:target, :any, required: true)

  defp filters_group_header(assigns) do
    ~H"""
    <div class={["pb-2 pr-3 h-10 flex items-center justify-between", @class]}>
      <p class="font-medium"><%= @title %></p>
      <button
        :if={group_changed?(@form, @default_filters, @group_name)}
        type="button"
        class="flex align-center text-link-primary hover:text-link-primary-hover"
        phx-click="reset-group"
        phx-value-group={@group_name}
        phx-target={@target}
      >
        <span>Reset</span>
      </button>
    </div>
    """
  end

  defp group_changed?(form, default_filters, group_name) do
    default_filters = Map.get(default_filters, group_name)

    Enum.any?(default_filters, fn {key, value} ->
      value != form.params[key]
    end)
  end

  defp filters_changed?(form, filters) do
    filters
    |> Enum.flat_map(fn {_, value} -> value end)
    |> Enum.any?(fn {key, value} ->
      value != form.params[key]
    end)
  end

  defp update_filters(active_filters, params) do
    functions =
      active_filters.functions
      |> Enum.reduce(%{}, fn {function, _}, acc ->
        Map.put(acc, function, Map.has_key?(params, function))
      end)

    execution_time =
      active_filters.execution_time
      |> Enum.reduce(%{}, fn {filter, value}, acc ->
        Map.put(acc, filter, Map.get(params, filter, value))
      end)

    case validate_execution_time(execution_time) do
      :ok -> {:ok, %{functions: functions, execution_time: execution_time}}
      {:error, errors} -> {:error, errors}
    end
  end

  defp validate_execution_time(execution_time) do
    min_time = execution_time["exec_time_min"]
    max_time = execution_time["exec_time_max"]
    min_time_unit = execution_time["min_unit"]
    max_time_unit = execution_time["max_unit"]

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
end
