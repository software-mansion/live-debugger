defmodule LiveDebugger.App.Debugger.NodeState.Web.AssignsSearch do
  @moduledoc """
  This component is used to add search functionality for assigns.
  It produces `search` and `search-submit` events handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.Components

  @required_assigns [:assigns_search_phrase]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:search_input, :handle_event, &handle_event/3)
    |> register_hook(:search_input)
  end

  attr(:placeholder, :string, default: "Search...")
  attr(:disabled?, :boolean, default: false)
  attr(:assigns_search_phrase, :string, default: "", doc: "The current search query for assigns")
  attr(:input_id, :string, default: "", doc: "The ID of the input element")

  @impl true
  def render(assigns) do
    ~H"""
    <Components.search_bar
      placeholder={@placeholder}
      search_phrase={@assigns_search_phrase}
      input_id={@input_id}
      debounce={250}
      class="h-7!"
    />
    """
  end

  defp handle_event("search", %{"search_phrase" => search_phrase}, socket) do
    socket
    |> assign(assigns_search_phrase: search_phrase)
    |> push_event("search_in_assigns", %{search_phrase: search_phrase})
    |> halt()
  end

  defp handle_event("search-submit", _params, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
