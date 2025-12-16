defmodule LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen do
  @moduledoc """
  Form for sending events to LiveView/LiveComponent.
  Includes its own fullscreen modal.
  """

  use LiveDebugger.App.Web, :live_component

  @handler_options [
    {"handle_info", "handle_info"},
    {"handle_event", "handle_event"},
    {"update", "update"}
  ]

  alias LiveDebugger.API.UserEvents

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign(:node_id, assigns.node_id)
    |> assign_form()
    |> ok()
  end

  attr(:id, :string, required: true)
  attr(:lv_process, :any, required: true)
  attr(:node_id, :any, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.fullscreen id={@id} title="Send Event" class="max-w-156">
        <div class="p-4">
          <.form for={@form} phx-submit="submit" phx-target={@myself}>
            <div class="flex flex-col gap-4">
              <.select field={@form[:handler]} label="Handler" options={handler_options()} />
              <.textarea
                field={@form[:message]}
                label="Message"
                rows="6"
                placeholder="Enter your message..."
                textarea_class="font-mono"
              />
              <.button variant="primary" type="submit" class="!w-full">
                Send
              </.button>
            </div>
          </.form>
        </div>
      </.fullscreen>
    </div>
    """
  end

  @impl true
  def handle_event("submit", %{"handler" => handler, "message" => message}, socket) do
    dbg(handler)
    dbg(message)

    UserEvents.send_info_message(socket.assigns.lv_process, message)

    socket
    |> push_event("#{socket.assigns.id}-close", %{})
    |> noreply()
  end

  defp assign_form(socket) do
    params = %{"handler" => "handle_info", "message" => ""}
    form = to_form(params, id: socket.assigns.id <> "-form")

    assign(socket, :form, form)
  end

  defp handler_options, do: @handler_options
end
