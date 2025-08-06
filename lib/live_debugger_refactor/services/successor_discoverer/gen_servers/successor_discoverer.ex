defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer do
  @moduledoc """
  It receives events from client associated with initializing windows.
  """

  use GenServer

  alias LiveDebuggerRefactor.Client
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Queries.Successor, as: SuccessorQueries

  alias LiveDebuggerRefactor.Bus
  alias LiveDebuggerRefactor.App.Events.FindSuccessor
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events.SuccessorFound
  alias LiveDebuggerRefactor.Services.SuccessorDiscoverer.Events.SuccessorNotFound

  defmodule State do
    @moduledoc """
    State of `SuccessorDiscoverer` service.
    """
    defstruct window_to_socket: %{}, socket_to_window: %{}

    @type t() :: %__MODULE__{
            window_to_socket: %{String.t() => String.t()},
            socket_to_window: %{String.t() => String.t()}
          }
  end

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    Client.receive_events()
    Bus.receive_events()

    {:ok, %State{}}
  end

  @impl true
  def handle_info({"window-initialized", payload}, state) do
    window_id = payload["window_id"]
    socket_id = payload["socket_id"]

    if is_binary(window_id) and is_binary(socket_id) do
      new_state =
        state
        |> put_window_to_socket(window_id, socket_id)
        |> put_socket_to_window(socket_id, window_id)

      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(%FindSuccessor{lv_process: lv_process}, state) do
    send(self(), {:find_successor, lv_process, 0})

    {:noreply, state}
  end

  @impl true
  def handle_info({:find_successor, lv_process, attempt}, state) when attempt < 3 do
    with nil <- SuccessorQueries.find_successor(lv_process),
         nil <- find_successor_using_state(state, lv_process.socket_id) do
      Process.send_after(self(), {:find_successor, lv_process, attempt + 1}, timeout(attempt))
      {:noreply, state}
    else
      successor ->
        socket_id = if is_binary(successor), do: successor, else: successor.socket_id

        if socket_id == lv_process.socket_id do
          Process.send_after(self(), {:find_successor, lv_process, attempt + 1}, timeout(attempt))
          {:noreply, state}
        else
          new_state = remove_socket_from_window(state, lv_process.socket_id)

          Bus.broadcast_event!(%SuccessorFound{
            old_socket_id: lv_process.socket_id,
            new_socket_id: socket_id
          })

          {:noreply, new_state}
        end
    end
  end

  @impl true
  def handle_info({:find_successor, lv_process, _attempt}, state) do
    Bus.broadcast_event!(%SuccessorNotFound{socket_id: lv_process.socket_id})
    {:noreply, state}
  end

  @impl true
  def handle_info(_, state) do
    {:noreply, state}
  end

  defp find_successor_using_state(state, old_socket_id) do
    window_id = get_window_id(state, old_socket_id)
    new_socket_id = get_socket_id(state, window_id)

    if is_binary(new_socket_id) do
      new_socket_id
    else
      nil
    end
  end

  defp put_window_to_socket(state, window_id, socket_id) do
    %{state | window_to_socket: Map.put(state.window_to_socket, window_id, socket_id)}
  end

  defp put_socket_to_window(state, socket_id, window_id) do
    %{state | socket_to_window: Map.put(state.socket_to_window, socket_id, window_id)}
  end

  defp get_window_id(state, socket_id) do
    state.socket_to_window[socket_id]
  end

  defp get_socket_id(state, window_id) do
    state.window_to_socket[window_id]
  end

  defp remove_socket_from_window(state, socket_id) do
    %{state | socket_to_window: Map.delete(state.socket_to_window, socket_id)}
  end

  defp timeout(_attempt = 0), do: 200
  defp timeout(1), do: 800
  defp timeout(_), do: 1000
end
