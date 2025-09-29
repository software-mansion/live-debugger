defmodule LiveDebugger.App.Debugger.NodeState.Web.AssignsSearch do
  @moduledoc """
  This component is used to add search functionality for assigns.
  It produces `search` and `search-submit` events handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  @required_assigns [:assign_search_phrase]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:search_input, :handle_event, &handle_event/3)
    |> register_hook(:search_input)
  end

  attr(:placeholder, :string, default: "Search...")
  attr(:disabled?, :boolean, default: false)
  attr(:assign_search_phrase, :string, default: "", doc: "The current search query for assigns")

  @impl true
  def render(assigns) do
    ~H"""
    <div class={[
      "flex shrink items-center rounded-[7px] outline outline-1 -outline-offset-1",
      "has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2",
      "outline-default-border has-[input:focus-within]:outline-ui-accent h-7!"
    ]}>
      <form phx-change="search" phx-submit="search-submit" class="flex items-center w-full h-full">
        <.icon
          name="icon-search"
          class={[
            "h-4 w-4 ml-3",
            (@disabled? && "text-gray-400") || "text-primary-icon"
          ]}
        />
        <input
          disabled={@disabled?}
          placeholder={@placeholder}
          value={@assign_search_phrase}
          phx-debounce="100"
          type="text"
          name="search_phrase"
          class="block remove-arrow w-16 sm:w-64 min-w-32 bg-surface-0-bg border-none py-2.5 pl-2 pr-3 text-xs text-primary-text placeholder:text-ui-muted focus:ring-0 disabled:!text-gray-500 disabled:placeholder-gray-300"
        />
      </form>
    </div>
    """
  end

  defp handle_event("search", %{"search_phrase" => search_phrase}, socket) do
    socket
    |> assign(assign_search_phrase: search_phrase)
    |> halt()
  end

  defp handle_event("search-submit", _params, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
