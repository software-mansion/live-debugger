defmodule LiveDebugger.App.Debugger.Components do
  @moduledoc """
  UI components used in the Debugger
  """
  use LiveDebugger.App.Web, :component

  attr(:placeholder, :string, default: "Search...")
  attr(:disabled?, :boolean, default: false)
  attr(:search_phrase, :string, default: "", doc: "The current search query")
  attr(:input_id, :string, default: "", doc: "The ID of the input element")
  attr(:debounce, :integer, default: 250, doc: "The debounce time in milliseconds")
  attr(:class, :string, default: "", doc: "Additional CSS classes for the input element")

  def search_bar(assigns) do
    ~H"""
    <div class={[
      "flex shrink items-center rounded-[7px] outline outline-1 -outline-offset-1",
      "has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2",
      "outline-default-border has-[input:focus-within]:outline-ui-accent",
      @class
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
          id={@input_id}
          disabled={@disabled?}
          placeholder={@placeholder}
          value={@search_phrase}
          phx-debounce={@debounce}
          type="text"
          name="search_phrase"
          class="block remove-arrow w-16 sm:w-64 min-w-32 bg-surface-0-bg border-none py-2.5 pl-2 pr-3 text-xs text-primary-text placeholder:text-ui-muted focus:ring-0 disabled:!text-gray-500 disabled:placeholder-gray-300"
        />
      </form>
    </div>
    """
  end
end
