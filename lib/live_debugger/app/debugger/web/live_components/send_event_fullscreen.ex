defmodule LiveDebugger.App.Debugger.Web.LiveComponents.SendEventFullscreen do
  @moduledoc """
  Form for sending events to LiveView/LiveComponent.
  Includes its own fullscreen modal.
  """

  use LiveDebugger.App.Web, :live_component

  alias LiveDebugger.API.UserEvents

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
              <.text_input
                :if={@form[:handler].value == "handle_event/3"}
                field={@form[:event]}
                label="Event"
                placeholder="e.g., click, submit"
              />
              <div class="flex flex-col gap-2">
                <.textarea
                  field={@form[:payload]}
                  label={payload_label(@form[:handler].value)}
                  rows="6"
                  placeholder={payload_placeholder(@form[:handler].value)}
                  textarea_class="font-mono"
                />
                <p :if={@message_error} class="text-xs text-error-text truncate">
                  <%= @message_error %>
                </p>
              </div>
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
  def handle_event("change", params, socket) do
    socket
    |> assign_form(params)
    |> noreply()
  end

  @impl true
  def handle_event(
        "submit",
        %{"handler" => "handle_event/3", "payload" => payload, "event" => event},
        socket
      ) do
    event = String.trim(event)
    payload = if String.trim(payload) == "", do: "%{}", else: payload

    with {:ok, _} <- validate_event(event),
         {:ok, term} <- parse_elixir_term(payload) do
      cid = get_cid(socket.assigns.node_id)
      UserEvents.send_lv_event(socket.assigns.lv_process, cid, event, term)

      socket
      |> assign(:message_error, nil)
      |> push_event("#{socket.assigns.id}-close", %{})
      |> noreply()
    else
      {:error, error} ->
        socket
        |> assign(:message_error, error)
        |> noreply()
    end
  end

  def handle_event(
        "submit",
        %{"handler" => handler, "payload" => payload},
        socket
      ) do
    case parse_elixir_term(payload) do
      {:ok, term} ->
        send_message(handler, socket.assigns.lv_process, socket.assigns.node_id, term)

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

  defp send_message("handle_info/2", lv_process, _node_id, payload) do
    UserEvents.send_info_message(lv_process, payload)
  end

  defp send_message("handle_cast/2", lv_process, _node_id, payload) do
    UserEvents.send_genserver_cast(lv_process, payload)
  end

  defp send_message("handle_call/3", lv_process, _node_id, payload) do
    UserEvents.send_genserver_call(lv_process, payload)
  end

  defp send_message("update/2", lv_process, node_id, payload) do
    UserEvents.send_component_update(lv_process, node_id, payload)
  end

  defp get_cid(node_id) when is_pid(node_id), do: nil
  defp get_cid(cid), do: cid

  defp validate_event(""), do: {:error, "Event cannot be empty"}
  defp validate_event(_event), do: {:ok, :valid}

  defp parse_elixir_term(""), do: {:error, "Payload cannot be empty"}

  defp parse_elixir_term(string) do
    with {:ok, quoted} <- Code.string_to_quoted(string),
         {:ok, term} <- safe_eval(quoted) do
      {:ok, term}
    else
      {:error, {_line, message, token}} when is_binary(message) and is_binary(token) ->
        {:error, "Syntax error: #{message}#{token}"}

      {:error, {_line, message, token}} ->
        {:error, "Syntax error: #{inspect(message)}#{inspect(token)}"}

      {:error, message} when is_binary(message) ->
        {:error, "Evaluation error: #{message}"}
    end
  end

  defp safe_eval(quoted) do
    try do
      {term, _binding} = Code.eval_quoted(quoted)
      {:ok, term}
    rescue
      e -> {:error, Exception.message(e)}
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
