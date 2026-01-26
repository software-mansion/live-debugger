defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.App.Debugger.Web.Components.ElixirDisplay
  alias LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsSearch
  alias LiveDebugger.App.Debugger.NodeState.Web.HookComponents.AssignsHistory
  alias LiveDebugger.App.Utils.TermNode
  alias Phoenix.LiveView.AsyncResult

  def loading(assigns) do
    ~H"""
    <div class="w-full flex-grow flex items-center justify-center">
      <.spinner size="sm" />
    </div>
    """
  end

  attr(:heading, :string, required: true)

  def failed(assigns) do
    ~H"""
    <.alert class="w-full" with_icon heading={@heading}>
      Check logs for more
    </.alert>
    """
  end

  attr(:term_node, TermNode, required: true)
  attr(:copy_string, :string, required: true)
  attr(:json_string, :string, required: true)
  attr(:fullscreen_id, :string, required: true)
  attr(:assigns_sizes, AsyncResult, required: true)
  attr(:assigns_search_phrase, :string, default: "")
  attr(:pinned_assigns, :map, default: %{})
  attr(:node_assigns_status, :atom, required: true)
  attr(:temporary_assigns, AsyncResult, required: true)

  def assigns_section(assigns) do
    ~H"""
    <div id="assigns-section-container" phx-hook="AssignsBodySearchHighlight">
      <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns" title_class="!min-w-18">
        <:title_sub_panel>
          <.assigns_status_indicator node_assigns_status={@node_assigns_status} />
        </:title_sub_panel>

        <:right_panel>
          <div class="flex gap-2">
            <AssignsSearch.render
              assigns_search_phrase={@assigns_search_phrase}
              input_id="assigns-search-input"
            />
            <AssignsHistory.button />
            <div class="flex">
              <.copy_button
                id="assigns-copy-button"
                variant="icon-button"
                value={@copy_string}
                class="rounded-e-none! border-r-0!"
              />
              <.copy_button
                id="json-assigns-copy-button"
                variant="button"
                text="JSON"
                value={@json_string}
                class="rounded-s-none!"
              />
            </div>
            <.fullscreen_button id={@fullscreen_id} />
          </div>
        </:right_panel>
        <div
          id="assigns-display-container"
          class="w-full h-max max-h-full overflow-y-auto"
          data-search_phrase={@assigns_search_phrase}
        >
          <.pinned_assigns_section
            id="pinned-assigns"
            term_node={@term_node}
            pinned_assigns={@pinned_assigns}
          />
          <.temporary_assigns_section id="temporary-assigns" temporary_assigns={@temporary_assigns} />
          <.all_assigns_section
            id="all-assigns"
            term_node={@term_node}
            assigns_sizes={@assigns_sizes}
          />
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
          <.pinned_assigns_section
            id="pinned-assigns-fullscreen"
            term_node={@term_node}
            pinned_assigns={@pinned_assigns}
          />
          <.temporary_assigns_section
            id="temporary-assigns-fullscreen"
            temporary_assigns={@temporary_assigns}
          />
          <.all_assigns_section
            id="all-assigns-fullscreen"
            term_node={@term_node}
            assigns_sizes={@assigns_sizes}
          />
        </div>
      </.fullscreen>
    </div>
    """
  end

  attr(:name, :string, required: true)
  attr(:icon, :string, default: nil)

  defp section_title(assigns) do
    ~H"""
    <div class="bg-surface-1-bg flex items-center h-10 gap-2 p-4 border-b border-default-border font-semibold text-secondary-text">
      <.icon :if={@icon} name={@icon} class="h-4 w-4" />
      <p><%= @name %></p>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:term_node, TermNode, required: true)
  attr(:pinned_assigns, :map, required: true)

  defp pinned_assigns_section(assigns) do
    assigns = assign(assigns, empty?: Enum.all?(assigns.pinned_assigns, fn {_, v} -> !v end))

    ~H"""
    <div id={@id}>
      <.section_title
        name={if(@empty?, do: "No pinned assigns", else: "Pinned assigns")}
        icon="icon-pin"
      />
      <div :if={not @empty?} class="p-4 border-b border-default-border overflow-x-auto">
        <div
          :for={{key, pinned} <- @pinned_assigns}
          :if={pinned}
          class="flex min-h-4.5 [&>div>button]:hidden hover:[&>div>button]:block"
        >
          <div class="w-4 shrink-0">
            <button
              class="text-button-red-content hover:text-button-red-content-hover"
              phx-click="unpin-assign"
              phx-value-key={key}
            >
              <.icon name="icon-pin-off" class="h-4 w-4" />
            </button>
          </div>
          <ElixirDisplay.static_term
            id={@id}
            node={Keyword.get(@term_node.children, String.to_existing_atom(key), %{})}
          />
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:temporary_assigns, AsyncResult, required: true)

  defp temporary_assigns_section(assigns) do
    assigns =
      assigns
      |> assign(entries: TermParser.term_to_display_tree(assigns.temporary_assigns).children)

    ~H"""
    <div id={@id}>
      <.section_title
        name={if(@temporary_assigns.result, do: "Temporary assigns", else: "No temporary assigns")}
        icon="icon-clock-3"
      />
      <.async_result :let={temporary_assigns} assign={@temporary_assigns}>
        <:loading>
          <div class="p-4">
            <.loading />
          </div>
        </:loading>
        <:failed>
          <div class="p-4">
            <.failed heading="Error while fetching temporary assigns" />
          </div>
        </:failed>

        <div :if={temporary_assigns} class="pl-8 p-4 border-b border-default-border overflow-x-auto">
          <div :for={{_key, term_node} <- TermParser.term_to_display_tree(temporary_assigns).children}>
            <ElixirDisplay.term id={@id} node={term_node} />
          </div>
        </div>
      </.async_result>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:term_node, TermNode, required: true)
  attr(:assigns_sizes, AsyncResult, required: true)

  defp all_assigns_section(assigns) do
    ~H"""
    <div id={@id}>
      <.section_title name="All assigns" />
      <div class="relative">
        <.assigns_sizes_section assigns_sizes={@assigns_sizes} id={@id <> "-size-label-container"} />
        <div class="p-4 overflow-x-auto">
          <ElixirDisplay.static_term id={@id} node={@term_node} selectable_level={1} />
        </div>
      </div>
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

  attr(:disabled?, :boolean, required: true)
  attr(:index, :integer, required: true)
  attr(:length, :integer, required: true)

  def assigns_history_navigation(assigns) do
    ~H"""
    <div class="flex justify-end items-center gap-2 mb-4">
      <div class="max-sm:max-w-70 flex items-center text-3xs py-2 px-3 rounded bg-button-secondary-bg text-button-secondary-content border-button-secondary-border border">
        <.icon name="icon-info" class="w-4 h-4 mr-2" />
        <span>
          The history is constructed from registered <b>render/1</b> callbacks
        </span>
      </div>
      <.icon_button
        variant="secondary"
        icon="icon-chevrons-right"
        phx-click="go-back-end"
        class="rotate-180"
        disabled={if(@disabled? || @index == @length - 1, do: true)}
      />
      <.icon_button
        variant="secondary"
        icon="icon-chevron-right"
        phx-click="go-back"
        class="rotate-180"
        disabled={if(@disabled? || @index == @length - 1, do: true)}
      />
      <span>
        <%= @index + 1 %> / <%= @length %>
      </span>
      <.icon_button
        variant="secondary"
        icon="icon-chevron-right"
        phx-click="go-forward"
        disabled={if(@disabled? || @index == 0, do: true)}
      />
      <.icon_button
        variant="secondary"
        icon="icon-chevrons-right"
        phx-click="go-forward-end"
        disabled={if(@disabled? || @index == 0, do: true)}
      />
    </div>
    """
  end

  attr(:node_assigns_status, :atom, required: true)

  defp assigns_status_indicator(assigns) do
    assigns = assign(assigns, get_status_indicator_params(assigns.node_assigns_status))

    ~H"""
    <.status_dot status={@status} pulse?={@pulse?} tooltip={@tooltip} />
    """
  end

  defp get_status_indicator_params(:updating) do
    [status: :warning, pulse?: true, tooltip: "Updating assigns..."]
  end

  defp get_status_indicator_params(:loaded) do
    [status: :success, pulse?: false, tooltip: "Assigns are up to date."]
  end

  defp get_status_indicator_params(:error) do
    [status: :error, pulse?: false, tooltip: "Error while fetching assigns."]
  end

  defp get_status_indicator_params(:disconnected) do
    [status: :error, pulse?: false, tooltip: "Disconnected from the LiveView process."]
  end
end
