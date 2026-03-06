defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.LiveComponents.FiltersForm do
  @moduledoc """
  Form for filtering traces by callback.
  It sends `{:filters_updated, filters}` to the parent LiveView after the form is submitted.

  You can use `LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Filters` to render additional

  Diff checkbox is hidden when node_id is passed since diffs are not supported in node traces.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Filters,
    as: FiltersComponents

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Debugger.ComponentsTree.Queries, as: ComponentsTreeQueries
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.Client
  alias LiveDebugger.API.SettingsStorage
  alias LiveDebugger.App.Debugger.ComponentsTree.Web.Components
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  @impl true
  def update(%{reset_form?: true}, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> maybe_assign_async_tree_form(socket.assigns.active_filters, socket.assigns.node_id)
    |> ok()
  end

  def update(%{action: :components_tree_updated}, socket) do
    socket
    |> assign_form(socket.assigns.active_filters)
    |> maybe_assign_async_tree_form(socket.assigns.active_filters, socket.assigns.node_id)
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    disabled? = Map.get(assigns, :disabled?, false)
    revert_button_visible? = Map.get(assigns, :revert_button_visible?, false)

    active_filters =
      assigns.filters |> Map.put_new(:components, %{FiltersHelpers.all_components() => true})

    socket
    |> assign(:id, assigns.id)
    |> assign(:active_filters, active_filters)
    |> assign(:lv_process, Map.get(assigns, :lv_process))
    |> assign(:node_id, assigns.node_id)
    |> assign(:disabled?, disabled?)
    |> assign(:revert_button_visible?, revert_button_visible?)
    |> assign(:default_filters, FiltersHelpers.default_filters(assigns.node_id))
    |> assign(:tree, nil)
    |> assign_form(assigns.filters)
    |> maybe_assign_async_tree_form(active_filters, assigns.node_id)
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
        <div class="w-full py-2 owerflow-auto">
          <div :if={!@node_id} class="px-4 border-b border-default-border">
            <.collapsible id="filters-component-tree-collapse" open={true}>
              <:label>
                <FiltersComponents.filters_group_header
                  title="Components tree"
                  class="pt-2"
                  group_name={:components}
                  target={@myself}
                  group_changed?={
                    FiltersHelpers.group_changed?(@form.params, @default_filters, :components)
                  }
                />
              </:label>
              <div class="flex flex-col gap-3 pb-4 ">
                <div class="flex flex-col">
                  <div class="flex flex-col gap-3 pb-4 ">
                    <div class="flex flex-col gap-1 pb-4">
                      <%= if @tree do %>
                        <Components.filters_tree_node tree_node={@tree} form={@form} level={0} />
                      <% else %>
                        <div class="text-sm text-gray-500 italic animate-pulse">
                          Loading components tree...
                        </div>
                      <% end %>
                    </div>
                  </div>
                </div>
              </div>
            </.collapsible>
          </div>

          <div class="px-4 border-b border-default-border">
            <.collapsible id="filters-callbacks-collapse" open={true}>
              <:label>
                <FiltersComponents.filters_group_header
                  title="Callbacks"
                  class="pt-2"
                  group_name={:functions}
                  target={@myself}
                  group_changed?={
                    FiltersHelpers.group_changed?(@form.params, @default_filters, :functions)
                  }
                />
              </:label>
              <div class="flex flex-col gap-3 pb-4 ">
                <.checkbox
                  :for={callback <- FiltersHelpers.get_callbacks(@node_id)}
                  field={@form[callback]}
                  label={callback}
                />
              </div>
            </.collapsible>
          </div>
          <div class="px-4 border-b border-default-border">
            <.collapsible id="filters-callbacks-collapse" open={true}>
              <:label>
                <FiltersComponents.filters_group_header
                  title="Execution Time"
                  class="pt-2"
                  group_name={:execution_time}
                  target={@myself}
                  group_changed?={
                    FiltersHelpers.group_changed?(@form.params, @default_filters, :execution_time)
                  }
                />
              </:label>
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
            </.collapsible>
          </div>

          <div :if={@node_id == nil} class="px-4 border-b border-default-border">
            <FiltersComponents.filters_group_header
              title="Other filters"
              class="pt-2"
              group_name={:other_filters}
              target={@myself}
              group_changed?={
                FiltersHelpers.group_changed?(@form.params, @default_filters, :other_filters)
              }
            />
            <div class="pb-5">
              <.checkbox field={@form[:trace_diffs]} label="Show LiveView diffs sent to browser" />
            </div>
          </div>

          <div class="flex pt-4 pb-2 px-4 items-center justify-between pr-3">
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

  @impl true
  def handle_event("highlight", params, socket) do
    socket
    |> highlight_element(params)
    |> noreply()
  end

  @impl true
  def handle_async({:tree, filters}, {:ok, {:ok, %{tree: %TreeNode{} = tree}}}, socket) do
    components_filters = Map.get(filters, :components, %{})

    filters_tree =
      flatten_tree(tree)
      |> Map.new(fn {id, _} ->
        encoded_id = FiltersHelpers.encode_component_id(id)

        {encoded_id, Map.get(components_filters, encoded_id, true)}
      end)

    default_filters =
      filters_tree
      |> Map.new(fn {id, _val} ->
        {id, true}
      end)

    new_params = Map.merge(socket.assigns.form.params, filters_tree)

    socket
    |> assign(:tree, tree)
    |> assign(
      :active_filters,
      Map.put(socket.assigns.active_filters, :components, filters_tree)
    )
    |> assign(
      :default_filters,
      Map.put(socket.assigns.default_filters, :components, default_filters)
    )
    |> assign(:form, to_form(new_params, id: socket.assigns.id))
    |> noreply()
  end

  @impl true
  def handle_async({:tree, _filters}, {:error, _error}, socket) do
    {:noreply, socket}
  end

  defp assign_form(
         socket,
         %{
           functions: functions,
           execution_time: execution_time,
           other_filters: other_filters
         } = filters
       ) do
    components = Map.get(filters, :components, %{})

    form =
      functions
      |> Map.merge(execution_time)
      |> Map.merge(other_filters)
      |> Map.merge(components)
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
    components =
      active_filters.components
      |> Enum.reduce(%{}, fn {component, _}, acc ->
        Map.put(acc, component, Map.has_key?(params, component))
      end)

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

    other_filters =
      active_filters.other_filters
      |> Enum.reduce(%{}, fn {filter, _}, acc ->
        Map.put(acc, filter, Map.has_key?(params, filter))
      end)

    case FiltersHelpers.validate_execution_time_params(execution_time) do
      :ok ->
        {:ok,
         %{
           functions: functions,
           execution_time: execution_time,
           other_filters: other_filters,
           components: components
         }}

      {:error, errors} ->
        {:error, errors}
    end
  end

  defp maybe_assign_async_tree_form(socket, filters, nil) do
    pid = socket.assigns.lv_process.pid

    start_async(socket, {:tree, filters}, fn ->
      ComponentsTreeQueries.fetch_components_tree(pid)
    end)
  end

  defp maybe_assign_async_tree_form(socket, _filters, _node_id) do
    socket
  end

  defp flatten_tree(%TreeNode{id: id, module: module, children: children}) do
    [{id, module} | flatten_tree(children)]
  end

  defp flatten_tree(nodes) when is_list(nodes) do
    Enum.flat_map(nodes, &flatten_tree/1)
  end

  defp highlight_element(%{assigns: %{lv_process: %LvProcess{alive?: true}}} = socket, params) do
    if SettingsStorage.get(:highlight_in_browser) do
      payload = %{
        attr: params["search-attribute"],
        val: params["search-value"],
        type: if(params["type"] == "live_view", do: "LiveView", else: "LiveComponent"),
        module: Parsers.module_to_string(params["module"]),
        id_value: params["id"],
        id_key: if(params["type"] == "live_view", do: "PID", else: "CID")
      }

      Client.push_event!(socket.assigns.lv_process.root_socket_id, "highlight", payload)
    end

    socket
  end

  defp highlight_element(socket, _), do: socket
end
