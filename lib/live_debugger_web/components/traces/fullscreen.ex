defmodule LiveDebuggerWeb.Components.Traces.Fullscreen do
  use LiveDebuggerWeb, :component

  alias LiveDebugger.Structs.Trace
  alias LiveDebuggerWeb.Components.ElixirDisplay
  alias LiveDebugger.Utils.TermParser
  alias LiveDebugger.Services.TraceService

  import Phoenix.LiveView

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
      <div class="w-full flex flex-col gap-4 items-start justify-center">
        <%= for {args, index} <- Enum.with_index(@trace_args) do %>
          <div :if={index > 0} class="border-t border-default-border w-full"></div>
          <p class="font-semibold shrink-0">
            Arg <%= index %> (<%= Trace.arg_name(@trace, index) %>)
          </p>
          <ElixirDisplay.term
            id={@id <> "-#{index}-fullscreen"}
            node={TermParser.term_to_display_tree(args)}
            level={1}
          />
        <% end %>
      </div>
    </.fullscreen>
    """
  end

  def attach_hook(socket) do
    attach_hook(socket, :traces_fullscreen, :handle_event, &handle_event/3)
  end

  # TODO this handler does not belong here - `phx-click` for it is not declared in the component
  defp handle_event("open-trace", %{"data" => string_id}, socket) do
    trace_id = String.to_integer(string_id)

    socket.assigns.lv_process.pid
    |> TraceService.get(trace_id)
    |> case do
      nil ->
        socket

      trace ->
        socket
        |> assign(displayed_trace: trace)
        |> push_event("trace-fullscreen-open", %{})
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}
end
