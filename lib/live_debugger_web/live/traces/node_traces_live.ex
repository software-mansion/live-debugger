defmodule LiveDebuggerWeb.Live.Traces.NodeTracesLive do
  @moduledoc """
  This nested live view displays the traces of a LiveView.
  """

  use LiveDebuggerWeb, :live_view

  require Logger

  alias LiveDebuggerWeb.Helpers.NestedLiveViewHelper

  alias LiveDebuggerWeb.Live.Traces.Hooks
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Live.Traces.Components
  alias LiveDebuggerWeb.Live.Traces.Helpers
  alias LiveDebuggerWeb.Helpers.FiltersHelper
  alias LiveDebuggerWeb.LiveComponents.FiltersForm

  @live_stream_limit 128
  @page_size 25

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "params" => assigns.params,
      "id" => assigns.id,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    parent_pid = session["parent_pid"]

    if connected?(socket) do
      parent_pid
      |> PubSubUtils.params_changed_topic()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:id, session["id"])
    |> assign(:parent_pid, session["parent_pid"])
    |> assign(:lv_process, session["lv_process"])
    |> stream(:existing_traces, [], reset: true)
    |> assign(:traces_empty?, true)
    |> assign(:traces_continuation, nil)
    |> assign(:existing_traces_status, :loading)
    |> assign(:displayed_trace, nil)
    |> assign(:trace_callback_running?, false)
    |> assign(:tracing_started?, false)
    |> NestedLiveViewHelper.assign_node_id(session)
    |> Helpers.assign_default_filters()
    |> Helpers.assign_current_filters()
    |> Components.ClearButton.init()
    |> Components.LoadMoreButton.init(@page_size)
    |> Components.Stream.init()
    |> Hooks.TracingFuse.init()
    |> Hooks.ExistingTraces.init(@page_size)
    |> Hooks.NewTraces.init(@live_stream_limit)
    |> Components.RefreshButton.init()
    |> Components.ToggleTracingButton.init()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:node_id, :map, required: true)
  attr(:socket_id, :string, required: true)

  @impl true
  def render(assigns) do
    assigns =
      assigns
      |> assign(
        applied_filters_number:
          FiltersHelper.calculate_selected_filters(
            assigns.current_filters,
            assigns.default_filters
          )
      )

    ~H"""
    <div class="max-w-full @container/traces flex flex-1">
      <.section title="Callback traces" id="traces" inner_class="mx-0 my-4 px-4" class="flex-1">
        <:right_panel>
          <div class="flex gap-2 items-center">
            <Components.ToggleTracingButton.toggle_tracing_button tracing_started?={@tracing_started?} />
            <Components.RefreshButton.refresh_button :if={not @tracing_started?} />
            <Components.ClearButton.clear_button :if={not @tracing_started?} />
            <FiltersForm.filters_button
              :if={not @tracing_started?}
              applied_filters_number={@applied_filters_number}
            />
            <.fullscreen id="filters-fullscreen" title="Filters">
              <.live_component
                module={FiltersForm}
                id="filters-form"
                node_id={@node_id}
                filters={@current_filters}
                default_filters={@default_filters}
              />
            </.fullscreen>
          </div>
        </:right_panel>
        <div class="w-full h-full">
          <Components.Stream.traces_stream
            id={@id}
            existing_traces_status={@existing_traces_status}
            existing_traces={@streams.existing_traces}
          />
          <Components.LoadMoreButton.load_more_button
            :if={not @tracing_started?}
            traces_continuation={@traces_continuation}
          />
        </div>
      </.section>
      <Components.trace_fullscreen id="trace-fullscreen" trace={@displayed_trace} />
    </div>
    """
  end

  @impl true
  def handle_info({:params_changed, new_params}, socket) do
    socket
    |> Hooks.TracingFuse.disable_tracing()
    |> NestedLiveViewHelper.assign_node_id(new_params)
    |> Helpers.assign_default_filters()
    |> Helpers.reset_current_filters()
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_info({:filters_updated, filters}, socket) do
    socket
    |> push_event("filters-fullscreen-close", %{})
    |> assign(:current_filters, filters)
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> noreply()
  end

  @impl true
  def handle_event("open-filters", _, socket) do
    socket
    |> push_event("filters-fullscreen-open", %{})
    |> noreply()
  end

  @impl true
  def handle_event("reset-filters", _, socket) do
    socket
    |> Helpers.reset_current_filters()
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> noreply()
  end
end
