defmodule LiveDebuggerWeb.Live.Traces.Components.FiltersSidebar do
  @moduledoc """
  Set of components that are used to display the filters in a sidebar.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Live.Traces.Hooks.ExistingTraces

  @required_assigns [:current_filters, :default_filters, :sidebar_hidden?, :tracing_started?]

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

  attr(:current_filters, :map, required: true)
  attr(:default_filters, :map, required: true)
  attr(:sidebar_hidden?, :boolean, required: true)
  attr(:tracing_started?, :boolean, required: true)

  def sidebar(assigns) do
    ~H"""
    <div class="w-max flex bg-sidebar-bg shadow-custom h-full">
      <div class="hidden lg:flex max-h-full flex-col w-72 border-x border-default-border lg:w-80 gap-1 justify-between">
        <.sidebar_content
          id="filters-sidebar-form"
          current_filters={@current_filters}
          default_filters={@default_filters}
          tracing_started?={@tracing_started?}
        />
      </div>
      <.sidebar_slide_over :if={not @sidebar_hidden?}>
        <.sidebar_content
          id="mobile-filters-sidebar-form"
          current_filters={@current_filters}
          default_filters={@default_filters}
          tracing_started?={@tracing_started?}
        />
      </.sidebar_slide_over>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:current_filters, :map, required: true)
  attr(:default_filters, :map, required: true)
  attr(:tracing_started?, :boolean, required: true)

  defp sidebar_content(assigns) do
    ~H"""
    <div>
      <div class="text-secondary-text font-semibold pt-6 pb-2 px-4">Filters</div>
      <div class="px-3">
        <.live_component
          module={LiveDebuggerWeb.LiveComponents.FiltersForm}
          id={@id}
          filters={@current_filters}
          default_filters={@default_filters}
          enabled?={not @tracing_started?}
        />
      </div>
    </div>
    """
  end

  defp handle_info({:filters_updated, filters}, socket) do
    socket
    |> assign(:current_filters, filters)
    |> assign(:traces_empty?, true)
    |> assign(:sidebar_hidden?, true)
    |> ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("reset-filters", _, socket) do
    socket
    |> assign(:current_filters, socket.assigns.default_filters)
    |> ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event("open-sidebar", _, socket) do
    {:halt, assign(socket, :sidebar_hidden?, false)}
  end

  defp handle_event("close_mobile_content", _params, socket) do
    {:halt, assign(socket, :sidebar_hidden?, true)}
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
