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

  @fullscreen_id "send-event-modal"

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign_form()
    |> ok()
  end

  attr(:id, :string, required: true)

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :fullscreen_id, @fullscreen_id)

    ~H"""
    <div>
      <.fullscreen id={@fullscreen_id} title="Send Event" class="max-w-156">
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
  def handle_event("submit", _params, socket) do
    socket
    |> push_event("#{@fullscreen_id}-close", %{})
    |> noreply()
  end

  defp assign_form(socket) do
    form =
      %{"handler" => "handle_info", "message" => ""}
      |> to_form(id: socket.assigns.id)

    assign(socket, :form, form)
  end

  defp handler_options, do: @handler_options
end
