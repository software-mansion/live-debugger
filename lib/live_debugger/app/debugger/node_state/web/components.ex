defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.App.Debugger.NodeState.Web.AssignsSearch
  alias LiveDebugger.Utils.Memory

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
  attr(:fullscreen_id, :string, required: true)
  attr(:assigns_search_phrase, :string, default: "")

  def assigns_section(assigns) do
    ~H"""
    <div id="assigns-section-container" phx-hook="AssignsBodySearchHighlight">
      <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
        <:right_panel>
          <div class="flex gap-2">
            <AssignsSearch.render
              assigns_search_phrase={@assigns_search_phrase}
              input_id="assigns-search-input"
            />
            <.copy_button
              id="assigns-copy-button"
              variant="icon-button"
              value={TermParser.term_to_copy_string(@assigns)}
            />
            <.fullscreen_button id={@fullscreen_id} />
          </div>
        </:right_panel>
        <div
          id="assigns-display-container"
          class="relative w-full h-max max-h-full p-4 overflow-y-auto"
          data-search_phrase={@assigns_search_phrase}
        >
          <div class="absolute top-2 right-2 z-10">
            <.assigns_size_label assigns={@assigns} id="display-container-size-label" />
          </div>
          <ElixirDisplay.term id="assigns-display" node={TermParser.term_to_display_tree(@assigns)} />
        </div>
      </.section>
      <.fullscreen id={@fullscreen_id} title="Assigns">
        <div class="flex justify-between p-2 border-b border-default-border">
          <AssignsSearch.render
            placeholder="Search assigns"
            assigns_search_phrase={@assigns_search_phrase}
            input_id="assigns-search-input-fullscreen"
          />
        </div>
        <div
          id="assigns-display-fullscreen-container"
          class="relative p-4"
          data-search_phrase={@assigns_search_phrase}
        >
          <div class="absolute top-0 right-2 z-10">
            <.assigns_size_label assigns={@assigns} id="display-fullscreen-size-label" />
          </div>
          <ElixirDisplay.term
            id="assigns-display-fullscreen-term"
            node={TermParser.term_to_display_tree(@assigns)}
          />
        </div>
      </.fullscreen>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:assigns, :list, required: true)

  def assigns_size_label(assigns) do
    ~H"""
    <div class="text-xs text-secondary-text flex gap-1">
      <span>Assigns size: </span>
      <.tooltip
        id={@id <> "-tooltip-heap"}
        content="Memory used by assigns inside the LiveView process."
        class="truncate"
        position="top-center"
      >
        <span><%= assigns_heap_size(assigns) %> heap</span>
      </.tooltip>
      <span> / </span>
      <.tooltip
        id={@id <> "-tooltip-serialized"}
        content="Size of assigns when encoded for transfer."
        class="truncate"
        position="top-center"
      >
        <%= assigns_serialized_size(@assigns) %> serialized
      </.tooltip>
    </div>
    """
  end

  defp assigns_heap_size(assigns) do
    assigns |> Memory.term_heap_size() |> Memory.bytes_to_pretty_string()
  end

  defp assigns_serialized_size(assigns) do
    assigns |> Memory.serialized_term_size() |> Memory.bytes_to_pretty_string()
  end
end
