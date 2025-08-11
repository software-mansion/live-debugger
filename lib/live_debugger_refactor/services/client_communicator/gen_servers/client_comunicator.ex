defmodule LiveDebuggerRefactor.Services.ClientCommunicator.GenServers.ClientCommunicator do
  @moduledoc false

  use GenServer

  alias LiveDebuggerRefactor.Client
  alias LiveDebuggerRefactor.API.LiveViewDiscovery
  alias LiveDebuggerRefactor.API.LiveViewDebug

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    Client.receive_events()

    {:ok, args}
  end

  @impl true
  def handle_info({"request-node-element", payload}, state) do
    socket_id = payload["socket_id"]
    type = payload["type"]
    id = payload["id"]
    root_socket_id = payload["root_socket_id"]
    dbg(payload)
    dbg(root_socket_id)

    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.filter(fn lv_process -> lv_process.socket_id == socket_id end)
    |> case do
      [lv_process] ->
        case type do
          "LiveView" ->
            Client.push_event!(root_socket_id, "found-node-element", %{
              "module" => lv_process.module
            })

            dbg(lv_process.module)

          _ ->
            lv_process.pid
            |> LiveViewDebug.live_components()
            |> case do
              {:ok, components} ->
                module =
                  components
                  |> Enum.find(fn component -> component.cid == id |> String.to_integer() end)
                  |> Map.get(:module)

                dbg(module)

                Client.push_event!(root_socket_id, "found-node-element", %{"module" => module})

              {:error, _} ->
                nil
            end
        end

      _ ->
        :ok
    end

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
