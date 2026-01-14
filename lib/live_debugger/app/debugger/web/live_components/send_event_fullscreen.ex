defmodule LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen do
  @moduledoc """
  Form for sending events to LiveView/LiveComponent.
  Includes its own fullscreen modal.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.App.Debugger.Actions.UserEvents, as: UserEventsActions
  alias LiveDebugger.App.Debugger.Web.Components.HandlerInfo

  @lc_handler_options [
    {"handle_event/3", "handle_event/3"},
    {"update/2", "update/2"}
  ]

  @lv_handler_options [
    {"handle_event/3", "handle_event/3"},
    {"handle_info/2", "handle_info/2"},
    {"handle_call/3", "handle_call/3"},
    {"handle_cast/2", "handle_cast/2"}
  ]

  @impl true
  def update(%{reset_form?: true}, socket) do
    socket
    |> assign(:message_error, nil)
    |> assign_form()
    |> ok()
  end

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:id, assigns.id)
    |> assign(:lv_process, assigns.lv_process)
    |> assign(:node_id, assigns.node_id)
    |> assign(:message_error, nil)
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
          <.form for={@form} phx-submit="submit" phx-change="change" phx-target={@myself}>
            <div class="flex flex-col gap-4">
              <.select field={@form[:handler]} label="Handler" options={handler_options(@node_id)} />
              <HandlerInfo.handler_info handler={@form[:handler].value} />
              <.text_input
                :if={@form[:handler].value == "handle_event/3"}
                field={@form[:event]}
                label="Event"
                placeholder="e.g., click, submit"
              />
              <div class="flex flex-col gap-2">
                <.codearea field={@form[:payload]} label={payload_label(@form[:handler].value)} />
                <p :if={@message_error} class="text-xs text-error-text truncate">
                  <%= @message_error %>
                </p>
              </div>
              <div class="flex gap-2">
                <.button
                  variant="secondary"
                  type="button"
                  class="!w-full"
                  phx-click="reset"
                  phx-target={@myself}
                >
                  Reset
                </.button>
                <.button variant="primary" type="submit" class="!w-full">
                  Send
                </.button>
              </div>
            </div>
          </.form>
        </div>
      </.fullscreen>
    </div>
    """
  end

  @impl true
  def handle_event("reset", _, socket) do
    socket
    |> assign(:message_error, nil)
    |> assign_form()
    |> noreply()
  end

  @impl true
  def handle_event("change", params, socket) do
    socket
    |> assign_form(params)
    |> noreply()
  end

  @impl true
  def handle_event("submit", params, socket) do
    lv_process = socket.assigns.lv_process
    node_id = socket.assigns.node_id

    case UserEventsActions.send(params, lv_process, node_id) do
      {:ok, _} ->
        socket
        |> assign(:message_error, nil)
        |> push_event("#{socket.assigns.id}-close", %{})
        |> noreply()

      {:error, error} ->
        socket
        |> assign(:message_error, error)
        |> noreply()
    end
  end

  defp assign_form(socket, params \\ %{}) do
    defaults = %{"handler" => "handle_event/3", "payload" => "", "event" => ""}
    params = Map.merge(defaults, params)
    form = to_form(params, id: socket.assigns.id <> "-form")

    assign(socket, :form, form)
  end

  defp handler_options(node_id) when is_pid(node_id), do: @lv_handler_options
  defp handler_options(_), do: @lc_handler_options

  defp payload_label("update/2"), do: "Assigns"
  defp payload_label("handle_event/3"), do: "Unsigned params"
  defp payload_label(_), do: "Message"

  defp payload_placeholder("update/2"), do: ~s|%{my_assign: "value"}|
  defp payload_placeholder("handle_event/3"), do: ~s|%{my_param: "value"}|
  defp payload_placeholder(_), do: ~s|{:my, "message"}|
end
