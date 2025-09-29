defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.App.Debugger.NodeState.Web.AssignsSearch

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
  attr(:assign_search_phrase, :string, default: "")

  def assigns_section(assigns) do
    ~H"""
    <div id="assigns-section-container" phx-hook="AssignsBodySearchHighlight">
      <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
        <:right_panel>
          <div class="flex gap-2">
            <AssignsSearch.render
              placeholder="Search assigns"
              assign_search_phrase={@assign_search_phrase}
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
          data-search_phrase={@assign_search_phrase}
        >
          <ElixirDisplay.term id="assigns-display" node={TermParser.term_to_display_tree(@assigns)} />
        </div>
      </.section>
      <.fullscreen id={@fullscreen_id} title="Assigns">
        <div class="flex justify-between p-2 border-b border-default-border">
          <AssignsSearch.render
            placeholder="Search assigns"
            assign_search_phrase={@assign_search_phrase}
            input_id="assigns-search-input-fullscreen"
          />
        </div>
        <div
          id="assigns-display-fullscreen-container"
          class="p-4"
          data-search_phrase={@assign_search_phrase}
        >
          <ElixirDisplay.term
            id="assigns-display-fullscreen-term"
            node={TermParser.term_to_display_tree(@assigns)}
          />
        </div>
      </.fullscreen>
    </div>
    """
  end
end
