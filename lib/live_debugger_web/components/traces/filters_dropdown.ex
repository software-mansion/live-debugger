defmodule LiveDebuggerWeb.Components.Traces.FiltersDropdown do
  use LiveDebuggerWeb, :component

  import Phoenix.LiveView

  def attach_hook(socket) do
    attach_hook(socket, :filters_dropdown, :handle_info, &handle_info/2)
  end

  attr(:node_id, :any, required: true)
  attr(:current_filters, :any, required: true)
  attr(:default_filters, :any, required: true)

  def filters_dropdown(assigns) do
    ~H"""
    <.live_component module={LiveDebuggerWeb.LiveComponents.LiveDropdown} id="filters-dropdown">
      <:button>
        <.button class="flex gap-2" variant="secondary" size="sm">
          <.icon name="icon-filters" class="w-4 h-4" />
          <div class="hidden @[29rem]/traces:block">Filters</div>
        </.button>
      </:button>
      <.live_component
        module={LiveDebuggerWeb.LiveComponents.FiltersForm}
        id="filters-form"
        node_id={@node_id}
        filters={@current_filters}
        default_filters={@default_filters}
      />
    </.live_component>
    """
  end

  defp handle_info({:filters_updated, _filters}, socket) do
    LiveDebuggerWeb.LiveComponents.LiveDropdown.close("filters-dropdown")

    {:cont, socket}
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
