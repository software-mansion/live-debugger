defmodule LiveDebugger.LiveComponents.SendEventForm do
  @moduledoc false

  use LiveDebuggerWeb, :live_component

  @impl true
  def update(%{lv_process: lv_process}, socket) do
    %{socket: debugged_socket} = :sys.get_state(lv_process.pid)

    debugged_socket =
      debugged_socket
      |> detach_hook(:live_debugger_hook, :handle_info)
      |> attach_hook(:live_debugger_hook, :handle_info, fn
        {:live_debugger_event, update_function}, socket ->
          socket = update_function.(socket)
          {:halt, socket}

        _, socket ->
          {:cont, socket}
      end)

    :sys.replace_state(lv_process.pid, fn state ->
      %{state | socket: debugged_socket}
    end)

    socket
    |> assign(lv_process: lv_process)
    |> assign(form: to_form(%{"module" => lv_process.module}))
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.form for={@form} class="flex flex-col gap-2" phx-submit="submit" phx-target={@myself}>
        <.input class="w-full" field={@form[:module]} />
        <.input class="w-full" field={@form[:function]} />
        <.input class="w-full" field={@form[:arguments]} placeholder="arg1; arg2; arg3..." />
        <.button type="submit">Send event</.button>
      </.form>
    </div>
    """
  end

  @impl true
  def handle_event("increment", _unsigned_params, socket) do
    # This will come from params - client is choosing which handler wants to be called
    module = socket.assigns.lv_process.module
    function = :handle_event

    send(
      socket.assigns.lv_process.pid,
      {:live_debugger_event,
       fn socket ->
         {_, socket} = apply(module, function, ["increment", %{}, socket])
         socket
       end}
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event("submit", params, socket) do
    module = String.to_existing_atom(params["module"])
    function = String.to_existing_atom(params["function"])

    args =
      params["arguments"]
      |> String.split(";")
      |> Enum.map(&String.trim/1)
      |> Enum.map(&parse/1)
      |> Enum.map(fn {:ok, term} -> term end)

    send(
      socket.assigns.lv_process.pid,
      {:live_debugger_event,
       fn socket ->
         {_, socket} = apply(module, function, args ++ [socket])
         socket
       end}
    )

    {:noreply, socket}
  end

  defp parse(str) when is_binary(str) do
    case str |> Code.string_to_quoted() do
      {:ok, terms} -> {:ok, _parse(terms)}
      {:error, _} -> {:invalid_terms}
    end
  end

  # atomic terms
  defp _parse(term) when is_atom(term), do: term
  defp _parse(term) when is_integer(term), do: term
  defp _parse(term) when is_float(term), do: term
  defp _parse(term) when is_binary(term), do: term

  defp _parse([]), do: []
  defp _parse([h | t]), do: [_parse(h) | _parse(t)]

  defp _parse({a, b}), do: {_parse(a), _parse(b)}

  defp _parse({:{}, _place, terms}) do
    terms
    |> Enum.map(&_parse/1)
    |> List.to_tuple()
  end

  defp _parse({:%{}, _place, terms}) do
    for {k, v} <- terms, into: %{}, do: {_parse(k), _parse(v)}
  end

  # to ignore functions and operators
  defp _parse({_term_type, _place, terms}), do: terms
end
