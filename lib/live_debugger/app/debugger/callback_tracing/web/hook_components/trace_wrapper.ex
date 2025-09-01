defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.TraceWrapper do
  @moduledoc """
  Collapsible trace wrapper.
  It produces `open_trace` and `toggle_collapsible` events handled by hooks added via `init/1`.

  Use `LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Trace` to compose the label of the trace.

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

  use LiveDebugger.App.Web, :hook_component

  import LiveDebugger.App.Web.Hooks.Flash, only: [push_flash: 4]

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay

  @required_assigns [:lv_process, :displayed_trace, :parent_pid]
  @trace_not_found_close_delay_ms 200

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:trace, :handle_event, &handle_event/3)
    |> attach_hook(:trace, :handle_info, &handle_info/2)
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
    assigns =
      assign(
        assigns,
        render_body?: assigns.trace_display.render_body?,
        trace: assigns.trace_display.trace
      )

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
          <%= render_slot(label) %>
        </div>
      </:label>
      <div class="relative">
        <div :if={@render_body?} class="absolute right-0 top-0 z-10">
          <.fullscreen_button
            id={"trace-fullscreen-#{@id}"}
            class="m-2"
            phx-click="open-trace"
            phx-value-trace-id={@trace.id}
          />
        </div>
        <div class="overflow-x-auto max-w-full max-h-[30vh] overflow-y-auto p-4">
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

  defp handle_event("open-trace", %{"trace-id" => string_trace_id}, socket) do
    socket
    |> get_trace(string_trace_id)
    |> case do
      nil ->
        socket
        |> push_flash(:error, "Trace has been removed.", socket.assigns.parent_pid)

      trace ->
        socket
        |> assign(displayed_trace: trace)
        |> push_event("trace-fullscreen-open", %{})
    end
    |> halt()
  end

  defp handle_event("toggle-collapsible", %{"trace-id" => string_trace_id}, socket) do
    socket
    |> get_trace(string_trace_id)
    |> case do
      nil ->
        handle_trace_not_found(string_trace_id)
        socket

      trace ->
        stream_insert_trace(socket, trace)
    end
    |> halt()
  end

  defp handle_event(_, _, socket), do: {:cont, socket}

  defp handle_info({:trace_wrapper_not_found, string_trace_id}, socket) do
    socket
    |> push_flash(:error, "Trace has been removed.", socket.assigns.parent_pid)
    |> push_event("existing_traces-#{string_trace_id}-collapsible", %{action: "close"})
    |> halt()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp get_trace(socket, string_trace_id) do
    TracesStorage.get_by_id!(socket.assigns.lv_process.pid, String.to_integer(string_trace_id))
  end

  defp handle_trace_not_found(string_trace_id) do
    Process.send_after(
      self(),
      {:trace_wrapper_not_found, string_trace_id},
      @trace_not_found_close_delay_ms
    )
  end

  defp stream_insert_trace(socket, trace) do
    stream_insert(
      socket,
      :existing_traces,
      trace |> TraceDisplay.from_trace() |> TraceDisplay.render_body()
    )
  end
end
