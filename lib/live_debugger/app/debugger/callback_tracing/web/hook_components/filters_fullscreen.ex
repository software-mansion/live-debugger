defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.FiltersFullscreen do
  @moduledoc """
  Hook component for displaying filters form in a fullscreen.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.LiveComponents.FiltersForm
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  @required_assigns [:current_filters, :node_id]

  @fullscreen_id "filters-fullscreen"
  @form_id "filters-fullscreen-form"

  @impl true
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> check_assigns!(@required_assigns)
    |> attach_hook(:filters, :handle_info, &handle_info/2)
    |> attach_hook(:filters, :handle_event, &handle_event/3)
    |> register_hook(:filters)
  end

  attr(:node_id, :any, default: nil)
  attr(:current_filters, :map, required: true)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, fullscreen_id: @fullscreen_id, form_id: @form_id)

    ~H"""
    <.fullscreen id={@fullscreen_id} title="Filters" class="max-w-112 min-w-[20rem]">
      <.live_component
        module={FiltersForm}
        id={@form_id}
        node_id={@node_id}
        filters={@current_filters}
      />
    </.fullscreen>
    """
  end

  @doc """
  Button which opens the filters form in a fullscreen.
  It also allows to reset the filters.
  """

  attr(:current_filters, :map, required: true)
  attr(:node_id, :any, default: nil)
  attr(:label_class, :string, default: "")

  def filters_button(assigns) do
    filters_number =
      assigns.node_id
      |> FiltersHelpers.default_filters()
      |> FiltersHelpers.count_selected_filters(assigns.current_filters)

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
    |> push_event("filters-fullscreen-close", %{})
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_event("open-filters", _, socket) do
    send_update(FiltersForm,
      id: @form_id,
      reset_form?: true
    )

    socket
    |> push_event("#{@fullscreen_id}-open", %{})
    |> halt()
  end

  defp handle_event("reset-filters", _, socket) do
    socket
    |> assign(:current_filters, FiltersHelpers.default_filters(socket.assigns.node_id))
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
