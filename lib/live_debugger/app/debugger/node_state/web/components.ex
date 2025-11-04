defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsSearch
  alias LiveDebugger.App.Utils.TermNode
  alias Phoenix.LiveView.AsyncResult

  alias LiveDebugger.App.Utils.TermParser

  def loading(assigns) do
    ~H"""
    <div class="w-full flex items-center justify-center">
      <.spinner size="sm" />
    </div>
    """
  end

  def failed(assigns) do
    ~H"""
    <.alert class="w-full" with_icon heading="Error while fetching node state">
      Check logs for more
    </.alert>
    """
  end

  attr(:assigns, :list, required: true)
  attr(:term_node, TermNode, required: true)
  attr(:copy_string, :string, required: true)
  attr(:fullscreen_id, :string, required: true)
  attr(:assigns_sizes, AsyncResult, required: true)
  attr(:assigns_search_phrase, :string, default: "")

  def assigns_section(assigns) do
    opened_term_node =
      TermNode.open_with_search_phrase(assigns.term_node, assigns.assigns_search_phrase)

    assigns = assign(assigns, term_node: opened_term_node)

    ~H"""
    <div id="assigns-section-container" phx-hook="AssignsBodySearchHighlight">
      <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
        <:right_panel>
          <div class="flex gap-2">
            <AssignsSearch.render
              assigns_search_phrase={@assigns_search_phrase}
              input_id="assigns-search-input"
            />
            <.copy_button id="assigns-copy-button" variant="icon-button" value={@copy_string} />
            <.fullscreen_button id={@fullscreen_id} />
          </div>
        </:right_panel>
        <div
          id="assigns-display-container"
          class="relative w-full h-max max-h-full p-4 overflow-y-auto"
          data-search_phrase={@assigns_search_phrase}
        >
          <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-container-size-label" />
          <ElixirDisplay.static_term node={@term_node} />
        </div>
      </.section>
      <.fullscreen id={@fullscreen_id} title="Assigns">
        <:search_bar_slot>
          <AssignsSearch.render
            assigns_search_phrase={@assigns_search_phrase}
            input_id="assigns-search-input-fullscreen"
          />
        </:search_bar_slot>
        <div
          id="assigns-display-fullscreen-container"
          class="relative p-4"
          data-search_phrase={@assigns_search_phrase}
        >
          <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-fullscreen-size-label" />
          <ElixirDisplay.static_term node={@term_node} />
        </div>
      </.fullscreen>
    </div>
    """
  end

  attr(:assigns_sizes, AsyncResult, required: true)
  attr(:id, :string, required: true)

  def assigns_sizes_section(assigns) do
    ~H"""
    <div class="absolute top-2 right-2 z-10 text-xs text-secondary-text flex gap-1">
      <span>Assigns size: </span>
      <.async_result :let={assigns_sizes} assign={@assigns_sizes}>
        <.tooltip
          id={@id <> "-tooltip-heap"}
          content="Memory used by assigns inside the LiveView process."
          class="truncate"
          position="top-center"
        >
          <span><%= assigns_sizes.heap_size %> heap</span>
        </.tooltip>
        <span> / </span>
        <.tooltip
          id={@id <> "-tooltip-serialized"}
          content="Size of assigns when encoded for transfer."
          class="truncate"
          position="top-center"
        >
          <span><%= assigns_sizes.serialized_size %> serialized</span>
        </.tooltip>
        <:loading>
          <span class="animate-pulse"> loading... </span>
        </:loading>
        <:failed>
          <span class="text-red-700"> error </span>
        </:failed>
      </.async_result>
    </div>
    """
  end

  attr(:stream_names, :list, required: true)
  attr(:existing_streams, :map, required: true)

  def stream_section(assigns) do
    ~H"""
    <div id="streams_section-container">
      <.section id="streams" class="h-max overflow-y-hidden" title="Streams">
        <:right_panel>
          <.streams_info_tooltip id="stream-info" />
        </:right_panel>
        <div
          id="streams-display-container"
          class="relative w-full h-max max-h-full p-4 overflow-y-auto"
        >
          <div :for={stream_name <- @stream_names} id={"#{stream_name}-display"}>
            <.stream_name_wrapper
              id={"#{stream_name}-collapsible"}
              stream_name={stream_name}
              existing_stream={Map.get(@existing_streams, stream_name, [])}
            >
              <:label>
                {stream_name}
              </:label>
            </.stream_name_wrapper>
          </div>
        </div>
      </.section>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:stream_name, :atom, required: true)
  attr(:existing_stream, Phoenix.LiveView.LiveStream, required: true)

  slot(:label, required: true)

  def stream_name_wrapper(assigns) do
    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border rounded last:mb-4 border-default-border"
      label_class="font-semibold bg-surface-1-bg p-2 py-3 rounded"
    >
      <:label>
        <%= render_slot(@label) %>
      </:label>
      <div class="relative">
        <div class="overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-4">
          <div id={"#{@stream_name}-stream"} phx-update="stream" class="flex flex-col gap-2">
            <%= for {dom_id, stream_element} <-@existing_stream do %>
              <.stream_element_wrapperid id={dom_id} dom_id={dom_id} stream_element={stream_element}>
                <:label>
                  <p class="font-semibold whitespace-nowrap break-keep grow-0 shrink-0">
                    <%= dom_id %>
                  </p>
                  <div class="grow min-w-0 text-secondary-text font-code font-normal text-3xs truncate pl-2">
                    <p
                      id={dom_id <> "-short-content"}
                      class="hide-on-open mt-0.5 overflow-hidden whitespace-nowrap"
                    >
                      <%= inspect(stream_element) %>
                    </p>
                  </div>
                </:label>
              </.stream_element_wrapperid>
            <% end %>
          </div>
        </div>
      </div>
    </.collapsible>
    """
  end

  attr(:id, :string, required: true)
  attr(:stream_element, :any, required: true)
  attr(:dom_id, :string, required: true)

  slot(:label, required: true)

  def stream_element_wrapper(assigns) do
    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border rounded last:mb-1 border-default-border"
      label_class="font-semibold bg-surface-1-bg p-1 py-1 rounded"
    >
      <:label>
        <%= render_slot(@label) %>
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
      <.icon name="icon-info" class="w-4 h-4" />
    </.tooltip>
    """
  end
end
