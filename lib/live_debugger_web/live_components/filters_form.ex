defmodule LiveDebuggerWeb.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  It sends `{:filters_updated, filters}` to the parent LiveView.
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
    |> assign(:default_filters, assigns.default_filters)
    |> assign_form(assigns.filters)
    |> ok()
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns, :selected_filters_number, calculate_selected_filters(assigns.form))

    ~H"""
    <div id={@id <> "-wrapper"}>
      <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
        <div class="w-[500px]">
          <div class="p-4">
            <p class="font-medium mb-4">Callbacks</p>
            <div class="flex flex-col gap-3">
              <%= for {function, arity} <- get_callbacks(@node_id) do %>
                <.checkbox field={@form[function]} label={"#{function}/#{arity}"} />
              <% end %>
            </div>
            <p class="font-medium mb-4 mt-6">Execution Time</p>
            <div class="flex gap-3 items-center">
              <.input field={@form[:exec_time_max]} type="number" min="0" placeholder="min" /> -
              <.input field={@form[:exec_time_min]} type="number" min="0" placeholder="max" />
            </div>
            <div class="mt-3 flex gap-3 items-center">
              <.time_input /> - <.time_input />
            </div>
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

  defp time_input(assigns) do
    ~H"""
    <div class="shadow-sm">
      <div class=" flex items-center rounded-[4px] outline outline-1 -outline-offset-1 outline-default-border has-[input:focus-within]:outline has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2 has-[input:focus-within]:outline-ui-accent">
        <input
          type="number"
          class="block remove-arrow max-w-20 bg-surface-0-bg border-none py-2.5 pl-2 pr-3 text-xs text-primary-text placeholder:text-ui-muted focus:ring-0"
          placeholder="min"
        />
        <div class="grid shrink-0 grid-cols-1 focus-within:relative">
          <select
            aria-label="Currency"
            class="border-none bg-surface-0-bg col-start-1 row-start-1 w-full appearance-none rounded-md py-1.5 pl-3 pr-7 text-xs text-secondary-text placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-ui-accent"
            defa
          >
            <option selected>&micro;s</option>
            <option>ms</option>
            <option>s</option>
          </select>
        </div>
      </div>
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
    min_time = Keyword.get(execution_time, :exec_time_min, 0)
    max_time = Keyword.get(execution_time, :exec_time_max, :infinity)

    if min_time != "" and max_time != "" and
         String.to_integer(min_time) > String.to_integer(max_time) do
      {:error, [exec_time_min: "min must be less than max", exec_time_max: ""]}
    else
      :ok
    end
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
