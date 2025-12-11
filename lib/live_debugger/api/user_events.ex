defmodule LiveDebugger.API.UserEvents do
  @moduledoc """
  API for user events.
  """

  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveComponent.CID

  def send_update(%LvProcess{} = lv_process, %CID{} = cid, payload) do
    Phoenix.LiveView.send_update(lv_process.pid, cid, payload)
  end

  def send_info(%LvProcess{} = lv_process, payload) do
    send(lv_process.pid, payload)
  end

  def send_cast(%LvProcess{} = lv_process, payload) do
    GenServer.cast(lv_process.pid, payload)
  end

  def send_call(%LvProcess{} = lv_process, payload) do
    GenServer.call(lv_process.pid, payload)
  end

  def send_event(%LvProcess{} = lv_process, cid \\ nil, event, unsigned_params) do
    payload = %{"event" => event, "value" => unsigned_params, "type" => "debug"}
    payload = if is_nil(cid), do: payload, else: Map.put(payload, "cid", cid)

    message = %Phoenix.Socket.Message{
      topic: "lv:#{lv_process.socket_id}",
      event: "event",
      payload: payload
    }

    send(lv_process.pid, message)
  end
end

# alias LiveDebugger.API.UserEvents
# [lv_process] = LiveDebugger.API.LiveViewDiscovery.debugged_lv_processes
# UserEvents.send_event(lv_process, %Phoenix.LiveComponent.CID{cid: 6}, :handle_event, "show_child", %{})
