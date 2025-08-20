defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.HookComponents.Stream do
  @moduledoc """
  Hook component for displaying the traces stream.
  It allows for composing style of traces visible in the stream.
  """

  use LiveDebugger.App.Web, :hook_component

  @required_assigns [:id, :existing_traces_status]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_traces)
    |> register_hook(:traces_stream)
  end

  attr(:id, :string, required: true)
  attr(:existing_traces_status, :atom, required: true)
  attr(:existing_traces, Phoenix.LiveView.LiveStream, required: true)

  slot(:trace, required: true, doc: "Used for styling trace element. Remember to add `id`")

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}-stream"} phx-update="stream" class="flex flex-col gap-2">
      <div id={"#{@id}-stream-empty"} class="only:block hidden text-secondary-text text-center">
        <div :if={@existing_traces_status == :ok}>
          No traces have been recorded yet.
        </div>
        <div :if={@existing_traces_status == :loading} class="w-full flex items-center justify-center">
          <.spinner size="sm" />
        </div>
        <.alert
          :if={@existing_traces_status == :error}
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
          <%= render_slot(@trace, {dom_id, wrapped_trace}) %>
        <% end %>
      <% end %>
    </div>
    """
  end

  @spec separator_stream_element() :: %{id: String.t()}
  def separator_stream_element() do
    %{id: "separator"}
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
