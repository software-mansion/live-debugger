defmodule LiveDebugger.Services.SuccessorDiscoverer.GenServers.SuccessorDiscoverer do
  @moduledoc """
  It discovers successors for debugged LiveView processes.
  There are two ways to discover successors:
  1. Using transport pid of the debugged process.
  2. Using window id of the debugged process.

  Let's say that someone is debugging with LiveDebugger LiveView process in `window_1`
  It means that there is a WebSocket connection between server and browser that is handled by specific process.
  The pid of this process is a transport_pid that is stored in the socket of debugged LiveView process.
  When user is using LiveNavigation to change navigate to different LiveView process WebSocket does not change.
  That means that transport_pid is the same for both LiveView processes.
  Knowing that we can find successor by transport_pid.

  The problem occurs when the same user decides to reload the page, or kill the BEAM system process.
  In such case WebSocket connection is closed, which means that transport_pid will change when new connection is established.
  This behavior leads to the second approach to discover successors - using window id.

  LiveDebugger requires user to attach our custom JS script to root layout of their debugged application.
  This script starts another WebSocket connection used for debugging.
  When this connection is established for the first time we save in sessionStorage window_id (which is a random UUID).
  Because this value is saved in sessionStorage it will be the same even when you kill the BEAM system process.
  Knowing that each time the WebSocket connection is established we send to this GenServer window_id and socket_id of LiveView displayed in the window.
  This way we can find in which window given LiveView is/was displayed, and find its successor.
  """

  use GenServer

  import LiveDebugger.Helpers

  alias LiveDebugger.Client
  alias LiveDebugger.Services.SuccessorDiscoverer.Queries.Successor, as: SuccessorQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Events.FindSuccessor
  alias LiveDebugger.Services.SuccessorDiscoverer.Events.SuccessorFound
  alias LiveDebugger.Services.SuccessorDiscoverer.Events.SuccessorNotFound
  alias LiveDebugger.Structs.LvProcess

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

    if not is_nil(window_id) and not is_nil(socket_id) do
      state
      |> put_window_to_socket(window_id, socket_id)
      |> put_socket_to_window(socket_id, window_id)
    else
      state
    end
    |> noreply()
  end

  @impl true
  def handle_info(%FindSuccessor{lv_process: lv_process}, state) do
    send(self(), {:find_successor, lv_process, 0})

    {:noreply, state}
  end

  @impl true
  def handle_info({:find_successor, lv_process, attempt}, state) when attempt < 3 do
    window_id = get_window_from_socket(state, lv_process.socket_id)
    new_socket_id = get_socket_from_window(state, window_id)
    previous_socket_id = lv_process.socket_id
    previous_pid = lv_process.pid

    lv_process
    |> SuccessorQueries.find_successor(new_socket_id)
    |> case do
      nil ->
        find_successor_after(lv_process, attempt)
        state

      # If the successor is the same as the debugged process, it means that successor did not report itself yet.
      %LvProcess{pid: ^previous_pid} ->
        find_successor_after(lv_process, attempt)
        state

      %LvProcess{} = successor ->
        Bus.broadcast_event!(%SuccessorFound{
          old_socket_id: previous_socket_id,
          new_lv_process: successor
        })

        state
    end
    |> noreply()
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

  defp put_window_to_socket(state, window_id, socket_id) do
    %{state | window_to_socket: Map.put(state.window_to_socket, window_id, socket_id)}
  end

  defp put_socket_to_window(state, socket_id, window_id) do
    %{state | socket_to_window: Map.put(state.socket_to_window, socket_id, window_id)}
  end

  defp get_window_from_socket(state, socket_id) do
    state.socket_to_window[socket_id]
  end

  defp get_socket_from_window(state, window_id) do
    state.window_to_socket[window_id]
  end

  defp find_successor_after(lv_process, attempt) do
    Process.send_after(self(), {:find_successor, lv_process, attempt + 1}, timeout(attempt))
  end

  defp timeout(0), do: 200
  defp timeout(1), do: 800
  defp timeout(_), do: 1000
end
