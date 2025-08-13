defmodule LiveDebuggerRefactor.Services.ClientCommunicator.GenServers.ClientCommunicator do
  @moduledoc false

  use GenServer

  alias LiveDebuggerRefactor.Client
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.Services.ClientCommunicator.Queries.LvProcess

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
    root_socket_id = payload["root_socket_id"]

    socket_id
    |> LvProcess.get_by_socket_id()
    |> case do
      {:ok, lv_process} ->
        process_node_element_request(lv_process, payload, root_socket_id)
        {:noreply, state}

      :not_found ->
        {:noreply, state}
    end
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp process_node_element_request(lv_process, payload, root_socket_id) do
    type = payload["type"]

    case type do
      "LiveView" ->
        send_live_view_element_info(lv_process, root_socket_id)

      _ ->
        cid = String.to_integer(payload["id"])

        lv_process
        |> LvProcess.get_live_component(cid)
        |> case do
          {:ok, component} ->
            send_component_info(component, root_socket_id)

          :not_found ->
            :ok
        end
    end
  end

  defp send_live_view_element_info(lv_process, root_socket_id) do
    Client.push_event!(root_socket_id, "found-node-element", %{
      "module" => Parsers.module_to_string(lv_process.module),
      "type" => "LiveView",
      "id_key" => "PID",
      "id_value" => Parsers.pid_to_string(lv_process.pid)
    })
  end

  defp send_component_info(component, root_socket_id) do
    Client.push_event!(root_socket_id, "found-node-element", %{
      "module" => Parsers.module_to_string(component.module),
      "type" => "LiveComponent",
      "id_key" => "CID",
      "id_value" => component.cid
    })
  end
end
