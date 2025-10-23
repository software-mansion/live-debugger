defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.SearchInput do
  @moduledoc """
  This component is used to add filtering by search query for callback traces.
  It produces `search` and `search-submit` events handled by hook added via `init/1`.
  """

  use LiveDebugger.App.Web, :hook_component

  alias LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks

  alias LiveDebugger.App.Debugger.Components

  @required_assigns [:trace_search_phrase]

  @impl true
  def init(socket) do
    socket
    |> check_hook!(:existing_traces)
    |> check_assigns!(@required_assigns)
    |> attach_hook(:search_input, :handle_event, &handle_event/3)
    |> register_hook(:search_input)
  end

  attr(:placeholder, :string, default: "Search...")
  attr(:disabled?, :boolean, default: false)
  attr(:trace_search_phrase, :string, default: "", doc: "The current search query for traces")
  attr(:class, :string, default: "", doc: "Additional CSS classes for the input element")

  @impl true
  def render(assigns) do
    ~H"""
    <Components.search_bar
      disabled?={@disabled?}
      search_phrase={@trace_search_phrase}
      input_id="trace-search-input"
      debounce={250}
      class={@class}
    />
    """
  end

  defp handle_event("search", %{"search_phrase" => search_phrase}, socket) do
    socket
    |> assign(trace_search_phrase: search_phrase)
    |> Hooks.ExistingTraces.assign_async_existing_traces()
    |> halt()
  end

  defp handle_event("search-submit", _params, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
