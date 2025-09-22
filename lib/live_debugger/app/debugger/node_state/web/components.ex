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
  attr(:assigns_keys, :map, default: %{})

  def assigns_section(assigns) do
    dbg(assigns.assigns)

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
      <div class="relative w-full h-max max-h-full overflow-y-auto">
        <div class="p-4 border-b border-default-border">
          <p :if={Enum.all?(@assigns_keys, fn {_, v} -> !v end)} class="text-secondary-text">
            You are not following any specific assign
          </p>
          <div
            :for={{key, pinned} <- @assigns_keys}
            :if={pinned}
            class="flex [&>div>button]:hidden hover:[&>div>button]:block"
          >
            <div class="w-4">
              <button class="text-error-text" phx-click="unpin-assign" phx-value-key={key}>
                <.icon name="icon-cross" class="h-4 w-4" />
              </button>
            </div>
            <ElixirDisplay.term
              id="elo"
              node={
                TermParser.to_key_value_node(
                  {key |> String.to_existing_atom(), @assigns[key |> String.to_existing_atom()]},
                  []
                )
              }
            />
          </div>
        </div>
        <div class="p-4">
          <ElixirDisplay.term
            id="assigns-display"
            node={TermParser.term_to_display_tree(@assigns)}
            selectable?={true}
          />
        </div>
      </div>
    </.section>
    <.fullscreen id={@fullscreen_id} title="Assigns">
      <div class="p-4 border-b border-default-border">
        <p :if={Enum.all?(@assigns_keys, fn {_, v} -> !v end)} class="text-secondary-text">
          You are not following any specific assign
        </p>
        <div :for={{key, pinned} <- @assigns_keys} :if={pinned}>
          <ElixirDisplay.term
            id="elo-fullscreen"
            node={
              TermParser.to_key_value_node(
                {key |> String.to_existing_atom(), @assigns[key |> String.to_existing_atom()]},
                []
              )
            }
          />
        </div>
      </div>
      <div class="p-4">
        <ElixirDisplay.term
          id="assigns-display-fullscreen-term"
          node={TermParser.term_to_display_tree(@assigns)}
        />
      </div>
    </.fullscreen>
    """
  end
end
