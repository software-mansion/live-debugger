defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
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
  attr(:fullscreen_id, :string, required: true)

  def assigns_section(assigns) do
    ~H"""
    <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns">
      <:right_panel>
        <div class="flex gap-2">
          <.copy_button
            id="assigns-copy-button"
            variant="icon-button"
            value={TermParser.term_to_copy_string(@assigns)}
          />
          <.fullscreen_button id={@fullscreen_id} />
        </div>
      </:right_panel>
      <div class="relative w-full h-max max-h-full p-4 overflow-y-auto">
        <ElixirDisplay.term id="assigns-display" node={TermParser.term_to_display_tree(@assigns)} />
      </div>
    </.section>
    <.fullscreen id={@fullscreen_id} title="Assigns">
      <ElixirDisplay.term
        id="assigns-display-fullscreen-term"
        node={TermParser.term_to_display_tree(@assigns)}
      />
    </.fullscreen>
    """
  end
end
