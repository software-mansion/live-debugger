defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.FiltersFullscreen do
  @moduledoc """
  Hook component for displaying filters form in a fullscreen.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.LiveComponents.FiltersForm
  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Helpers.Filters, as: FiltersHelpers

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Components.TraceSettings
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
  attr(:display_mode, :atom, required: true, values: [:normal, :dropdown])

  def filters_button(assigns) do
    filters_number =
      assigns.node_id
      |> FiltersHelpers.default_filters()
      |> FiltersHelpers.count_selected_filters(assigns.current_filters)

    assigns = assign(assigns, :applied_filters_number, filters_number)

    ~H"""
    <div class="flex">
      <TraceSettings.maybe_add_tooltip
        display_mode={@display_mode}
        id="filters-tooltip"
        content="Filters"
        position="top-center"
      >
        <.button
          variant="secondary"
          aria-label="Open filters"
          size="sm"
          class={[
            "flex !w-7 !h-7 px-[0.2rem] py-[0.2rem] items-center justify-center",
            if(@applied_filters_number > 0, do: "rounded-r-none"),
            @label_class,
            @display_mode == :dropdown && "!w-full !border-none !h-full"
          ]}
          phx-click="open-filters"
        >
          <TraceSettings.action_icon display_mode={@display_mode} icon="icon-filters" label="Filters" />

          <span :if={@applied_filters_number > 0}>
            (<%= @applied_filters_number %>)
          </span>
        </.button>
      </TraceSettings.maybe_add_tooltip>
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

    LiveDebugger.App.Web.LiveComponents.LiveDropdown.close("tracing-options-dropdown")

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
