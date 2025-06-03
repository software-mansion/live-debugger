defmodule LiveDebuggerWeb.Live.Traces.Components.Stream do
  @moduledoc """
  This component is used to display the traces stream.
  It uses under the hood the `Trace` component to display the traces.
  The `Trace` component produces the `toggle-collapsible` and `trace-fullscreen` which are handled in the `Trace` component hook.
  """

  use LiveDebuggerWeb, :hook_component

  alias LiveDebuggerWeb.Live.Traces.Components.Trace

  @doc """
  Initializes the component by attaching the hook to the socket.
  Since the `Trace` component is used by this component, we need to attach the hook to the socket.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(:id)
    |> check_assigns!(:existing_traces_status)
    |> check_streams!(:existing_traces)
    |> Trace.init()
    |> register_hook(:traces_stream)
  end

  @doc """
  Renders the traces stream.
  It is used to display the traces stream.
  """

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
          <Trace.trace id={dom_id} wrapped_trace={wrapped_trace} />
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
