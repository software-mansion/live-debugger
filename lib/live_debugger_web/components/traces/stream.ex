defmodule LiveDebuggerWeb.Components.Traces.Stream do
  use LiveDebuggerWeb, :component

  import LiveDebuggerWeb.Components.Traces.Trace

  def attach_hook(socket) do
    socket
    |> LiveDebuggerWeb.Components.Traces.Trace.attach_hook()
    |> register_hook(:traces_stream)
  end

  attr(:id, :string, required: true)
  attr(:existing_traces_status, :atom, required: true)
  attr(:existing_traces, :any, required: true)

  def traces_stream(assigns) do
    ~H"""
    <div id={"#{@id}-stream"} phx-update="stream" class="flex flex-col gap-2">
      <div id={"#{@id}-stream-empty"} class="only:block hidden text-secondary-text">
        <div :if={@existing_traces_status == :ok}>
          No traces have been recorded yet.
        </div>
        <div :if={@existing_traces_status == :loading} class="w-full flex items-center justify-center">
          <.spinner size="sm" />
        </div>
        <.alert
          :if={@existing_traces_status == :error}
          variant="danger"
          with_icon
          heading="Error fetching historical callback traces"
        >
          New events will still be displayed as they come. Check logs for more information
        </.alert>
      </div>
      <%= for {dom_id, wrapped_trace} <- @existing_traces do %>
        <%= if wrapped_trace.id == "separator" do %>
          <.separator id={dom_id} />
        <% else %>
          <.trace id={dom_id} wrapped_trace={wrapped_trace} />
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:id, :string, required: true)

  defp separator(assigns) do
    ~H"""
    <div id={@id}>
      <div class="h-6 my-1 font-normal text-xs text-secondary-text flex align items-center">
        <div class="border-b border-default-border grow"></div>
        <span class="mx-2">Past Traces</span>
        <div class="border-b border-default-border grow"></div>
      </div>
    </div>
    """
  end
end
