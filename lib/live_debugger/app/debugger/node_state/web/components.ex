defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsSearch
  alias LiveDebugger.App.Utils.TermNode
  alias Phoenix.LiveView.AsyncResult

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

  attr(:term_node, TermNode, required: true)
  attr(:copy_string, :string, required: true)
  attr(:fullscreen_id, :string, required: true)
  attr(:assigns_sizes, AsyncResult, required: true)
  attr(:assigns_search_phrase, :string, default: "")
  attr(:selected_assigns, :map, default: %{})

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
          class="w-full h-max max-h-full overflow-y-auto"
          data-search_phrase={@assigns_search_phrase}
        >
          <div id="pinned-assigns" class="p-4 border-b border-default-border">
            <.selected_assigns_section term_node={@term_node} selected_assigns={@selected_assigns} />
          </div>
          <div id="all-assigns" class="p-4 relative">
            <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-container-size-label" />
            <ElixirDisplay.static_term node={@term_node} selectable_level={1} />
          </div>
        </div>
      </.section>
      <.fullscreen id={@fullscreen_id} title="Assigns">
        <:search_bar_slot>
          <AssignsSearch.render
            assigns_search_phrase={@assigns_search_phrase}
            input_id="assigns-search-input-fullscreen"
          />
        </:search_bar_slot>
        <div id="assigns-display-fullscreen-container" data-search_phrase={@assigns_search_phrase}>
          <div class="p-4 border-b border-default-border">
            <.selected_assigns_section term_node={@term_node} selected_assigns={@selected_assigns} />
          </div>
          <div class="p-4 relative">
            <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-fullscreen-size-label" />
            <ElixirDisplay.static_term node={@term_node} selectable_level={1} />
          </div>
        </div>
      </.fullscreen>
    </div>
    """
  end

  attr(:term_node, TermNode, required: true)
  attr(:selected_assigns, :map, required: true)

  defp selected_assigns_section(assigns) do
    ~H"""
    <p :if={Enum.all?(@selected_assigns, fn {_, v} -> !v end)} class="text-secondary-text">
      You are not following any specific assign
    </p>
    <div
      :for={{key, pinned} <- @selected_assigns}
      :if={pinned}
      class="flex [&>div>button]:hidden hover:[&>div>button]:block"
    >
      <div class="w-4">
        <button class="text-error-text" phx-click="unpin-assign" phx-value-key={key}>
          <.icon name="icon-cross" class="h-4 w-4" />
        </button>
      </div>
      <ElixirDisplay.static_term node={
        Keyword.get(@term_node.children, String.to_existing_atom(key), %{})
      } />
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
end
