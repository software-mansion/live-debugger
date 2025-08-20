defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  It sends `{:filters_updated, filters}` to the parent LiveView after the form is submitted.

  You can use `LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Filters` to render additional
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Filters,
    as: FiltersComponents

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers
  alias LiveDebugger.App.Utils.Parsers

  @impl true
  def update(%{reset_form?: true}, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    disabled? = Map.get(assigns, :disabled?, false)
    revert_button_visible? = Map.get(assigns, :revert_button_visible?, false)

    socket
    |> assign(:id, assigns.id)
    |> assign(:active_filters, assigns.filters)
    |> assign(:node_id, assigns.node_id)
    |> assign(:disabled?, disabled?)
    |> assign(:revert_button_visible?, revert_button_visible?)
    |> assign(:default_filters, FiltersHelpers.default_filters(assigns.node_id))
    |> assign_form(assigns.filters)
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:filters, :map, required: true)

  attr(:node_id, :any,
    required: true,
    doc: "TreeNode id or nil. When nil, filters are applied to all callbacks."
  )

  attr(:disabled?, :boolean, default: false)
  attr(:revert_button_visible?, :boolean, default: false)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(errors: assigns.form.errors)
      |> assign(form_valid?: Enum.empty?(assigns.form.errors))

    ~H"""
    <div id={@id <> "-wrapper"} class={if @disabled?, do: "opacity-50 pointer-events-none"}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="w-full px-1">
          <FiltersComponents.filters_group_header
            title="Callbacks"
            group_name={:functions}
            target={@myself}
            group_changed?={FiltersHelpers.group_changed?(@form.params, @default_filters, :functions)}
          />
          <div class="flex flex-col gap-3 pl-0.5 pb-4 border-b border-default-border">
            <.checkbox
              :for={callback <- FiltersHelpers.get_callbacks(@node_id)}
              field={@form[callback]}
              label={callback}
            />
          </div>
          <FiltersComponents.filters_group_header
            title="Execution Time"
            class="pt-2"
            group_name={:execution_time}
            target={@myself}
            group_changed?={
              FiltersHelpers.group_changed?(@form.params, @default_filters, :execution_time)
            }
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
              <%= if FiltersHelpers.filters_changed?(@form.params, @active_filters) do %>
                <.button
                  variant="primary"
                  type="submit"
                  class={if(not @form_valid?, do: "opacity-50 pointer-events-none")}
                >
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
              :if={FiltersHelpers.filters_changed?(@form.params, @default_filters)}
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

  def handle_event("reset", _params, socket) do
    socket
    |> assign_form(socket.assigns.default_filters)
    |> noreply()
  end

  def handle_event("revert", _params, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> noreply()
  end

  def handle_event("reset-group", %{"group" => group}, socket) do
    group_name = String.to_existing_atom(group)
    group_filters = Map.get(socket.assigns.default_filters, group_name)

    socket
    |> assign_form(group_filters)
    |> noreply()
  end

  defp assign_form(socket, %{functions: functions, execution_time: execution_time}) do
    form =
      functions
      |> Map.merge(execution_time)
      |> to_form(id: socket.assigns.id)

    assign(socket, :form, form)
  end

  defp assign_form(socket, filters_map) when is_map(filters_map) do
    form = socket.assigns.form

    form =
      form.params
      |> Map.merge(filters_map)
      |> to_form(id: socket.assigns.id)

    assign(socket, :form, form)
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

    case FiltersHelpers.validate_execution_time_params(execution_time) do
      :ok -> {:ok, %{functions: functions, execution_time: execution_time}}
      {:error, errors} -> {:error, errors}
    end
  end
end
