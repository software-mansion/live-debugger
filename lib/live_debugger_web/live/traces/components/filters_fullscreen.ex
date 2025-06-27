defmodule LiveDebuggerWeb.Live.Traces.Components.FiltersFullscreen do
  @moduledoc """
  Set of components that are used to display the filters in a fullscreen.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Live.Traces.Hooks.ExistingTraces

  @required_assigns [:current_filters, :default_filters]

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

  attr(:node_id, :map, default: nil)
  attr(:current_filters, :map, required: true)
  attr(:default_filters, :map, required: true)

  @doc """
  Renders the filters fullscreen component.
  It produces the `filters_updated` event that can be handled by the hook provided in the `init/1` function.
  """
  def filters_fullscreen(assigns) do
    ~H"""
    <.fullscreen id="filters-fullscreen" title="Filters" class="max-w-112 min-w-[20rem]">
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

  attr(:current_filters, :map, required: true)
  attr(:default_filters, :map, required: true)
  attr(:label_class, :string, default: "")

  def filters_button(assigns) do
    filters_number = calculate_selected_filters(assigns.current_filters, assigns.default_filters)
    assigns = assign(assigns, :applied_filters_number, filters_number)

    ~H"""
    <div class="flex">
      <.button
        variant="secondary"
        aria-label="Open filters"
        size="sm"
        class={["flex gap-1", if(@applied_filters_number > 0, do: "rounded-r-none")]}
        phx-click="open-filters"
      >
        <.icon name="icon-filters" class="w-4 h-4" />
        <span class={["ml-1", @label_class]}>Filters</span>
        <span :if={@applied_filters_number > 0}>
          (<%= @applied_filters_number %>)
        </span>
      </.button>
      <.icon_button
        :if={@applied_filters_number > 0}
        icon="icon-cross"
        variant="secondary"
        phx-click="reset-filters"
        class="rounded-l-none border-l-0 h-[30px]! w-[30px]!"
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
    send_update(LiveDebuggerWeb.LiveComponents.FiltersForm,
      id: "filters-fullscreen-form",
      reset_form?: true
    )

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

  defp calculate_selected_filters(current_filters, default_filters) do
    flat_current_filters =
      current_filters
      |> Enum.flat_map(fn {_key, value} -> value end)
      |> Enum.reject(fn {key, _val} -> key in [:min_unit, :max_unit] end)

    flat_default_filters =
      default_filters
      |> Enum.flat_map(fn {_key, value} -> value end)
      |> Enum.reject(fn {key, _val} -> key in [:min_unit, :max_unit] end)

    Enum.count(flat_current_filters, fn {key, value} ->
      value != get_flat_filter(flat_default_filters, key)
    end)
  end

  defp get_flat_filter(filters, key) do
    Enum.find(filters, fn {filter, _value} -> filter == key end) |> elem(1)
  end
end
