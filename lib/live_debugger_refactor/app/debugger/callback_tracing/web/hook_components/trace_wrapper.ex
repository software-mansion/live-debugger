defmodule LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.HookComponents.TraceWrapper do
  @moduledoc """
  Collapsible trace wrapper.
  It produces `open_trace` and `toggle_collapsible` events handled by hooks added via `init/1`.

  Use `LiveDebuggerRefactor.App.Debugger.CallbackTracing.Web.Components.Trace` to compose the label of the trace.

  ## Examples

      <TraceWrapper.render id="trace-1" trace_display={@trace_display}>
        <:label class="grid-cols-[auto]">
          Trace Label
        </:label>
        <:body>
          Trace Body
        </:body>
      </TraceWrapper.render>
  """

  use LiveDebuggerRefactor.App.Web, :hook_component

  alias LiveDebuggerRefactor.App.Debugger.CallbackTracing.TraceDisplay

  @impl true
  def init(socket) do
    socket
    |> attach_hook(:trace, :handle_event, &handle_event/3)
    |> register_hook(:trace)
  end

  attr(:id, :string, required: true)
  attr(:trace_display, TraceDisplay, required: true)

  slot(:body, required: true)

  slot :label, required: true do
    attr(:class, :string, doc: "Additional class for label")
  end

  @impl true
  def render(assigns) do
    ~H"""
    <.collapsible
      id={@id}
      icon="icon-chevron-right"
      chevron_class="w-5 h-5 text-accent-icon"
      class="max-w-full border border-default-border rounded last:mb-4"
      label_class={[
        "font-semibold bg-surface-1-bg p-2 py-3",
        @trace.type == :exception_from && "border border-error-icon"
      ]}
      phx-click={if(@render_body?, do: nil, else: "toggle-collapsible")}
      phx-value-trace-id={@trace.id}
    >
      <:label>
        <div
          :for={label <- @label}
          id={@id <> "-label"}
          class={["w-[90%] grow grid items-center gap-x-3 ml-2" | List.wrap(label[:class])]}
        >
          <%= render_slot(label, assigns.trace_display) %>
        </div>
      </:label>
      <div class="relative">
        <div :if={@render_body?} class="absolute right-0 top-0 z-10">
          <.fullscreen_button
            id={"trace-fullscreen-#{@id}"}
            class="m-2"
            phx-click="open-trace"
            phx-value-data={@trace.id}
          />
        </div>
        <div class="flex flex-col gap-4 overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-4">
          <%= if @render_body? do %>
            <%= render_slot(@body) %>
          <% else %>
            <div class="w-full flex items-center justify-center">
              <.spinner size="sm" />
            </div>
          <% end %>
        </div>
      </div>
    </.collapsible>
    """
  end

  defp handle_event("open-trace", _, socket), do: {:halt, socket}
  defp handle_event("toggle-collapsible", _, socket), do: {:halt, socket}
  defp handle_event(_, _, socket), do: {:cont, socket}
end
