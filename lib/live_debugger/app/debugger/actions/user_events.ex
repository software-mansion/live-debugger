defmodule LiveDebugger.App.Debugger.Actions.UserEvents do
  @moduledoc """
  Actions for sending user-triggered events to LiveView/LiveComponent processes.
  """

  alias LiveDebugger.API.UserEvents
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.CommonTypes

  @doc """
  Sends a message based on form params. Dispatches to `send_lv_event/4` or `send_message/4`.

  Returns `{:ok, result}` on success or `{:error, reason}` on failure.
  """
  @spec send(map(), LvProcess.t(), pid() | CommonTypes.cid()) ::
          {:ok, term()} | {:error, String.t()}
  def send(
        %{"handler" => "handle_event/3", "event" => event, "payload" => payload},
        lv_process,
        node_id
      ) do
    send_lv_event(lv_process, node_id, event, payload)
  end

  def send(%{"handler" => handler, "payload" => payload}, lv_process, node_id) do
    send_message(handler, lv_process, node_id, payload)
  end

  @doc """
  Sends a LiveView event (handle_event/3).

  Returns `{:ok, result}` on success or `{:error, reason}` on failure.
  """
  @spec send_lv_event(LvProcess.t(), pid() | CommonTypes.cid(), String.t(), String.t()) ::
          {:ok, term()} | {:error, String.t()}
  def send_lv_event(lv_process, node_id, event, payload_string) do
    event = String.trim(event)
    payload_string = if String.trim(payload_string) == "", do: "%{}", else: payload_string

    with {:ok, _} <- validate_event(event),
         {:ok, payload} <- parse_elixir_term(payload_string) do
      result = UserEvents.send_lv_event(lv_process, get_cid(node_id), event, payload)
      {:ok, result}
    end
  end

  @doc """
  Sends a message to LiveView/LiveComponent based on the handler type.

  Supported handlers:
  - `"handle_info/2"` - sends info message
  - `"handle_cast/2"` - sends GenServer cast
  - `"handle_call/3"` - sends GenServer call
  - `"update/2"` - sends component update

  Returns `{:ok, result}` on success or `{:error, reason}` on failure.
  """
  @spec send_message(String.t(), LvProcess.t(), pid() | CommonTypes.cid(), String.t()) ::
          {:ok, term()} | {:error, String.t()}
  def send_message(handler, lv_process, node_id, payload_string) do
    case parse_elixir_term(payload_string) do
      {:ok, payload} ->
        result = dispatch_message(handler, lv_process, node_id, payload)
        {:ok, result}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Parses a string into an Elixir term.

  Returns `{:ok, term}` on success or `{:error, reason}` on failure.
  """
  @spec parse_elixir_term(String.t()) :: {:ok, term()} | {:error, String.t()}
  def parse_elixir_term(""), do: {:error, "Payload cannot be empty"}

  def parse_elixir_term(string) do
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

  defp dispatch_message("handle_info/2", lv_process, _node_id, payload) do
    UserEvents.send_info_message(lv_process, payload)
  end

  defp dispatch_message("handle_cast/2", lv_process, _node_id, payload) do
    UserEvents.send_genserver_cast(lv_process, payload)
  end

  defp dispatch_message("handle_call/3", lv_process, _node_id, payload) do
    UserEvents.send_genserver_call(lv_process, payload)
  end

  defp dispatch_message("update/2", lv_process, node_id, payload) do
    UserEvents.send_component_update(lv_process, node_id, payload)
  end

  defp get_cid(node_id) when is_pid(node_id), do: nil
  defp get_cid(cid), do: cid

  defp validate_event(""), do: {:error, "Event cannot be empty"}
  defp validate_event(_event), do: {:ok, :valid}

  defp safe_eval(quoted) do
    try do
      {term, _binding} = Code.eval_quoted(quoted)
      {:ok, term}
    rescue
      e -> {:error, Exception.message(e)}
    end
  end
end
