defmodule LiveDebugger.App.Debugger.Streams.Web.Components do
  @moduledoc """
  UI components used in the Streams.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser

  def loading(assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center p-4">
      <.spinner size="sm" />
    </div>
    """
  end

  def failed(assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center p-4">
      <.alert class="w-full" with_icon heading="Error while fetching stream from render traces">
        Check logs for more
      </.alert>
    </div>
    """
  end

  attr(:id, :string, required: true)
  slot(:display, required: true)

  def streams_section(assigns) do
    ~H"""
    <.collapsible_section
      id={@id}
      class="h-max overflow-y-hidden"
      title="Streams"
      save_state_in_browser={true}
    >
      <:right_panel>
        <.streams_info_tooltip id="stream-info" />
      </:right_panel>
      <%= render_slot(@display) %>
    </.collapsible_section>
    """
  end

  attr(:stream_names, :list, required: true)
  attr(:existing_streams, :map, required: true)

  def streams_display_container(assigns) do
    ~H"""
    <div id="streams-display-container" class="flex flex-col gap-2 w-full h-max p-4 overflow-y-auto">
      <div :for={stream_name <- @stream_names} id={"#{stream_name}-display"}>
        <.stream_name_wrapper
          id={"#{stream_name}-collapsible"}
          stream_name={stream_name}
          existing_stream={Map.get(@existing_streams, stream_name, [])}
        />
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:stream_name, :atom, required: true)
  attr(:existing_stream, Phoenix.LiveView.LiveStream, required: true)

  def stream_name_wrapper(assigns) do
    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border rounded border-default-border"
      label_class="font-semibold bg-surface-1-bg p-2 py-3 rounded"
    >
      <:label>
        {@stream_name}
      </:label>

      <div class="overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-3">
        <div id={"#{@stream_name}-stream"} phx-update="stream" class="flex flex-col gap-2">
          <%= for {dom_id, stream_element} <-@existing_stream do %>
            <.stream_element_wrapper dom_id={dom_id} stream_element={stream_element} />
          <% end %>
        </div>
      </div>
    </.collapsible>
    """
  end

  attr(:stream_element, :any, required: true)
  attr(:dom_id, :string, required: true)

  def stream_element_wrapper(assigns) do
    ~H"""
    <.collapsible
      id={@dom_id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border rounded last:mb-1 border-default-border"
      label_class="font-semibold bg-surface-1-bg p-1 py-1 rounded"
      phx-hook="Highlight"
      phx-value-search-attribute="id"
      phx-value-search-value={@dom_id}
      phx-value-type="StreamItem"
      phx-value-id={@dom_id}
    >
      <:label>
        <p class="font-semibold whitespace-nowrap break-keep grow-0 shrink-0">
          <%= @dom_id %>
        </p>
        <div class="grow min-w-0 text-secondary-text font-code font-normal text-3xs truncate pl-2">
          <p
            id={@dom_id <> "-short-content"}
            class="hide-on-open mt-0.5 overflow-hidden whitespace-nowrap"
          >
            <%= inspect(@stream_element) %>
          </p>
        </div>
      </:label>
      <div class="flex flex-col gap-4 w-full overflow-auto p-2">
        <ElixirDisplay.term
          id={"#{@dom_id}-term"}
          node={TermParser.term_to_display_tree(@stream_element)}
        />
      </div>
    </.collapsible>
    """
  end

  attr(:id, :string, required: true)

  def streams_info_tooltip(assigns) do
    ~H"""
    <.tooltip
      id={@id <> "-tooltip"}
      content="Streams are built from render traces. You won’t be able to reconstruct the entire stream if those traces are garbage collected."
      position="top-center"
    >
      <.icon name="icon-info" class="w-4 h-4 bg-button-secondary-content" />
    </.tooltip>
    """
  end
end
