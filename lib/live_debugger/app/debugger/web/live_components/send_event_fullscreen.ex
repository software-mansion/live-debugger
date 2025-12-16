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
          <.form for={@form} phx-submit="submit" phx-target={@myself}>
            <div class="flex flex-col gap-4">
              <.select field={@form[:handler]} label="Handler" options={handler_options()} />
              <div class="flex flex-col gap-2">
                <.textarea
                  field={@form[:message]}
                  label="Message (Elixir term)"
                  rows="6"
                  placeholder={~s|{:hello, "world", 123}|}
                  textarea_class="font-mono"
                />
                <p :if={@message_error} class="text-xs text-error-text">
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
  def handle_event("submit", %{"handler" => handler, "message" => message}, socket) do
    case parse_elixir_term(message) do
      {:ok, term} ->
        dbg(handler)
        dbg(term)

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

  defp parse_elixir_term(""), do: {:error, "Message cannot be empty"}

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

  defp assign_form(socket) do
    params = %{"handler" => "handle_info", "message" => ""}
    form = to_form(params, id: socket.assigns.id <> "-form")

    assign(socket, :form, form)
  end

  defp handler_options, do: @handler_options
end
