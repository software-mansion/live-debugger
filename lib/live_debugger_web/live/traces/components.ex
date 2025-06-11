defmodule LiveDebuggerWeb.Live.Traces.Components do
  @moduledoc """
  UI components for the TracesLive module.
  """

  use LiveDebuggerWeb, :live_component

  alias LiveDebugger.Structs.Trace
  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser

  attr(:id, :string, required: true)
  attr(:trace, :map, default: nil)

  def trace_fullscreen(assigns) do
    assigns =
      case assigns.trace do
        nil ->
          assigns
          |> assign(:callback_name, "Unknown trace")
          |> assign(:trace_args, [])

        trace ->
          assigns
          |> assign(:callback_name, Trace.callback_name(trace))
          |> assign(:trace_args, trace.args)
      end

    ~H"""
    <.fullscreen id={@id} title={@callback_name}>
      <div class="w-full flex flex-col gap-4 items-start justify-center hover:[&>div>div>div>button]:hidden">
        <.trace_body id={@id <> "-fullscreen"} trace_args={@trace_args} trace={@trace} />
      </div>
    </.fullscreen>
    """
  end

  attr(:id, :string, required: true)
  attr(:trace_args, :list, required: true)
  attr(:trace, :map, required: true)

  def trace_body(assigns) do
    ~H"""
    <%= for {args, index} <- Enum.with_index(@trace_args) do %>
      <div :if={index > 0} class="border-t border-default-border w-full"></div>
      <div class="flex flex-col gap-4 w-full [&>div>div>button]:hidden hover:[&>div>div>button]:block">
        <div class="shrink-0 flex gap-2 items-center h-4">
          <p class="font-semibold">
            Arg <%= index %> (<%= Trace.arg_name(@trace, index) %>)
          </p>
          <.copy_button id={"#{@id}-arg-#{index}"} value={TermParser.term_to_copy_string(args)} />
        </div>
        <ElixirDisplay.term
          id={@id <> "-#{index}"}
          node={TermParser.term_to_display_tree(args)}
          level={1}
        />
      </div>
    <% end %>
    """
  end
end
