defmodule LiveDebugger.Services.ClientCommunicator.GenServers.ClientCommunicator do
  @moduledoc false

  use GenServer

  alias LiveDebugger.Client
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.Services.ClientCommunicator.Queries.LvProcess

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(args) do
    Client.receive_events()
    {:ok, args}
  end

  @impl true
  def handle_info(
        {"request-node-element",
         %{"root_socket_id" => root_socket_id, "socket_id" => socket_id} = payload},
        state
      ) do
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

  defp process_node_element_request(lv_process, %{"type" => "LiveView"}, root_socket_id) do
    send_live_view_info(lv_process, root_socket_id)
  end

  defp process_node_element_request(
         lv_process,
         %{"type" => "LiveComponent", "id" => id},
         root_socket_id
       ) do
    cid = String.to_integer(id)

    lv_process
    |> LvProcess.get_live_component(cid)
    |> case do
      {:ok, component} ->
        send_live_component_info(component, root_socket_id)

      :not_found ->
        :ok
    end
  end

  defp send_live_view_info(lv_process, root_socket_id) do
    Client.push_event!(root_socket_id, "found-node-element", %{
      "module" => Parsers.module_to_string(lv_process.module),
      "type" => "LiveView",
      "id_key" => "PID",
      "id_value" => Parsers.pid_to_string(lv_process.pid)
    })
  end

  defp send_live_component_info(component, root_socket_id) do
    Client.push_event!(root_socket_id, "found-node-element", %{
      "module" => Parsers.module_to_string(component.module),
      "type" => "LiveComponent",
      "id_key" => "CID",
      "id_value" => component.cid
    })
  end
end
