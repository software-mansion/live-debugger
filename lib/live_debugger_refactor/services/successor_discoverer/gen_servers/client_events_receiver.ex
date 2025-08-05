defmodule LiveDebuggerRefactor.Services.SuccessorDiscoverer.GenServers.ClientEventsReceiver do
  @moduledoc """
  It receives events from client associated with initializing windows.
  """

  use GenServer

  alias LiveDebuggerRefactor.Client

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

      {:noreply, new_state |> dbg()}
    else
      {:noreply, state}
    end
  end

  defp put_window_to_socket(state, window_id, socket_id) do
    %{state | window_to_socket: Map.put(state.window_to_socket, window_id, socket_id)}
  end

  defp put_socket_to_window(state, socket_id, window_id) do
    %{state | socket_to_window: Map.put(state.socket_to_window, socket_id, window_id)}
  end
end
