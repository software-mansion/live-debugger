defmodule LiveDebuggerWeb.Live.Traces.Components.Filters do
  @moduledoc """
  Set of components that are used to display the filters.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Live.Traces.Hooks.ExistingTraces

  @required_assigns [:node_id, :current_filters, :default_filters]

  @doc """
  Initializes the component by checking the assigns and streams and attaching the hook to the socket.
  The hook is used to handle the `filters_updated` event.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filters, :handle_info, &handle_info/2)
    |> attach_hook(:filters, :handle_event, &handle_event/3)
    |> register_hook(:filters)
  end

  attr(:node_id, :map, required: true)
  attr(:current_filters, :map, required: true)
  attr(:default_filters, :map, required: true)

  @doc """
  Renders the filters fullscreen component.
  It produces the `filters_updated` event that can be handled by the hook provided in the `init/1` function.
  """
  def filters_fullscreen(assigns) do
    ~H"""
    <.fullscreen id="filters-fullscreen" title="Filters">
      <.live_component
        module={LiveDebuggerWeb.LiveComponents.FiltersForm}
        id="filters-fullscreen-form"
        node_id={@node_id}
        filters={@current_filters}
        default_filters={@default_filters}
      />
    </.fullscreen>
    """
  end

  @doc """
  Renders the filters button.
  It produces the `open-filters` and `reset-filters` events that can be handled by the hook provided in the `init/1` function.
  """

  # TODO: It should be calculated
  attr(:applied_filters_number, :integer, default: 5)

  def filters_button(assigns) do
    ~H"""
    <div class="flex">
      <.button
        variant="secondary"
        size="sm"
        class={["flex gap-2", if(@applied_filters_number > 0, do: "rounded-r-none")]}
        phx-click="open-filters"
      >
        <.icon name="icon-filters" class="w-4 h-4" />
        <div class="flex gap-1">
          <span class="hidden @[29rem]/traces:block">Filters</span>
          <span :if={@applied_filters_number > 0}>
            (<%= @applied_filters_number %>)
          </span>
        </div>
      </.button>
      <.icon_button
        :if={@applied_filters_number > 0}
        icon="icon-cross"
        variant="secondary"
        phx-click="reset-filters"
        class="rounded-l-none border-l-0"
      />
    </div>
    """
  end

  defp handle_info({:filters_updated, filters}, socket) do
    socket
    |> assign(:current_filters, filters)
    |> assign(:traces_empty?, true)
    |> push_event("filters-fullscreen-close", %{})
    |> ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("open-filters", _, socket) do
    socket
    |> push_event("filters-fullscreen-open", %{})
    |> halt()
  end

  defp handle_event("reset-filters", _, socket) do
    socket
    |> assign(:current_filters, socket.assigns.default_filters)
    |> ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
