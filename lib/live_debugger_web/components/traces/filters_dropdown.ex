defmodule LiveDebuggerWeb.Components.Traces.FiltersDropdown do
  @moduledoc """
  This component is used to display the filters dropdown.
  It produces the `filters_updated` event that can be handled by the hook provided in the `init/1` function.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Hooks.Traces.ExistingTraces, as: ExistingTracesHook

  @doc """
  Initializes the component by checking the assigns and streams and attaching the hook to the socket.
  The hook is used to handle the `filters_updated` event.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> check_assigns!(:node_id)
    |> check_assigns!(:current_filters)
    |> check_assigns!(:default_filters)
    |> check_assigns!(:traces_empty?)
    |> attach_hook(:filters_dropdown, :handle_info, &handle_info/2)
    |> register_hook(:filters_dropdown)
  end

  @doc """
  Renders the filters dropdown.
  It produces the `filters_updated` event that can be handled by the hook provided in the `init/1` function.
  """

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

  defp handle_info({:filters_updated, filters}, socket) do
    LiveDebuggerWeb.LiveComponents.LiveDropdown.close("filters-dropdown")

    socket
    |> assign(:current_filters, filters)
    |> assign(:traces_empty?, true)
    |> ExistingTracesHook.assign_async_existing_traces()
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}
end
