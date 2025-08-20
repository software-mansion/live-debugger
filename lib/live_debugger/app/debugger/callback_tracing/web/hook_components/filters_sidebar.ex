defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.FiltersSidebar do
  @moduledoc """
  Hook component for displaying filters form in a sidebar.
  This component handles "open-sidebar" event which can be triggered by other components.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.LiveComponents.FiltersForm

  @required_assigns [:current_filters, :sidebar_hidden?, :tracing_started?]

  @impl true
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filters, :handle_info, &handle_info/2)
    |> attach_hook(:filters, :handle_event, &handle_event/3)
    |> register_hook(:filters)
  end

  attr(:current_filters, :map, required: true)
  attr(:sidebar_hidden?, :boolean, required: true)
  attr(:tracing_started?, :boolean, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <.sidebar_slide_over id="filters-sidebar" sidebar_hidden?={@sidebar_hidden?}>
      <div>
        <div class="text-secondary-text font-semibold pt-6 pb-2 px-4">Filters</div>
        <div class="px-3">
          <.live_component
            module={FiltersForm}
            id="filters-sidebar-form"
            node_id={nil}
            filters={@current_filters}
            disabled?={@tracing_started?}
            revert_button_visible?={true}
          />
        </div>
      </div>
    </.sidebar_slide_over>
    """
  end

  defp handle_info({:filters_updated, filters}, socket) do
    socket
    |> assign(:current_filters, filters)
    |> assign(:sidebar_hidden?, true)
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("open-sidebar", _, socket) do
    {:halt, assign(socket, :sidebar_hidden?, false)}
  end

  defp handle_event("close-sidebar", _, socket) do
    {:halt, assign(socket, :sidebar_hidden?, true)}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
