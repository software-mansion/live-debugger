defmodule LiveDebugger.App.Debugger.NodeState.Web.Components do
  @moduledoc """
  UI components used in the Node State.
  """

  use LiveDebugger.App.Web, :component

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
  attr(:pinned_assigns, :map, default: %{})

  def assigns_section(assigns) do
    opened_term_node =
      TermNode.open_with_search_phrase(assigns.term_node, assigns.assigns_search_phrase)

    assigns = assign(assigns, term_node: opened_term_node)

    ~H"""
    <div id="assigns-section-container" phx-hook="AssignsBodySearchHighlight">
      <.section id="assigns" class="h-max overflow-y-hidden" title="Assigns" title_class="!min-w-14">
        <:right_panel>
          <div class="flex gap-2">
            <AssignsSearch.render
              assigns_search_phrase={@assigns_search_phrase}
              input_id="assigns-search-input"
            />
            <AssignsHistory.button />
            <.copy_button id="assigns-copy-button" variant="icon-button" value={@copy_string} />
            <.fullscreen_button id={@fullscreen_id} />
          </div>
        </:right_panel>
        <div
          id="assigns-display-container"
          class="w-full h-max max-h-full overflow-y-auto"
          data-search_phrase={@assigns_search_phrase}
        >
          <div id="pinned-assigns" class="p-4 border-b border-default-border overflow-x-auto">
            <.pinned_assigns_section
              id="pinned-"
              term_node={@term_node}
              pinned_assigns={@pinned_assigns}
            />
          </div>
          <div id="all-assigns" class="relative">
            <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-container-size-label" />
            <div class="p-4 overflow-x-auto">
              <ElixirDisplay.static_term id="assigns-" node={@term_node} selectable_level={1} />
            </div>
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
          <div class="p-4 border-b border-default-border overflow-x-auto">
            <.pinned_assigns_section
              id="pinned-fullscreen-"
              term_node={@term_node}
              pinned_assigns={@pinned_assigns}
            />
          </div>
          <div class="relative">
            <.assigns_sizes_section assigns_sizes={@assigns_sizes} id="display-fullscreen-size-label" />
            <div class="p-4 overflow-x-auto">
              <ElixirDisplay.static_term id="fullscreen-" node={@term_node} selectable_level={1} />
            </div>
          </div>
        </div>
      </.fullscreen>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:term_node, TermNode, required: true)
  attr(:pinned_assigns, :map, required: true)

  defp pinned_assigns_section(assigns) do
    ~H"""
    <p :if={Enum.all?(@pinned_assigns, fn {_, v} -> !v end)} class="text-secondary-text">
      You have no pinned assigns.
    </p>
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

  attr(:status, :atom, required: true)
  attr(:pulse?, :boolean, default: false)

  def status_dot(assigns) do
    assigns =
      case assigns.status do
        :success -> assign(assigns, :bg_class, "bg-status-dot-success-bg")
        :warning -> assign(assigns, :bg_class, "bg-status-dot-warning-bg")
        :error -> assign(assigns, :bg_class, "bg-status-dot-error-bg")
      end

    ~H"""
    <.tooltip id="loading-dot-tooltip" content="Updating assigns sizes">
      <span class="relative flex size-2">
        <span
          :if={@pulse?}
          class={"absolute inline-flex h-full w-full animate-ping rounded-full #{@bg_class} opacity-75"}
        >
        </span>
        <span class={"relative inline-flex size-2 rounded-full #{@bg_class}"}></span>
      </span>
    </.tooltip>
    """
  end
end
