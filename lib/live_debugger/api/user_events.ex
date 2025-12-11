defmodule LiveDebugger.API.UserEvents do
  @moduledoc """
  API for user events.
  """

  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveComponent.CID
  alias Phoenix.Socket.Message

  def send_event(lv_process, cid \\ nil, handler_type, payload)

  def send_event(%LvProcess{} = lv_process, %CID{} = cid, :update, payload) do
    Phoenix.LiveView.send_update(lv_process.pid, cid, payload)
  end

  def send_event(%LvProcess{} = lv_process, nil, :handle_info, payload) do
    send(lv_process.pid, payload)
  end

  def send_event(%LvProcess{} = lv_process, nil, :handle_cast, payload) do
    GenServer.cast(lv_process.pid, payload)
  end

  def send_event(%LvProcess{} = lv_process, nil, :handle_call, payload) do
    GenServer.call(lv_process.pid, payload)
  end

  def send_event(%LvProcess{} = lv_process, nil, :handle_event, event, params) do
    payload = %{"event" => event, "value" => params, "type" => "debug"}

    message = %Message{
      topic: "lv:#{lv_process.socket_id}",
      event: "event",
      payload: payload
    }

    send(lv_process.pid, message)
  end

  def send_event(%LvProcess{} = lv_process, %CID{cid: cid}, :handle_event, event, params) do
    payload = %{"cid" => cid, "event" => event, "value" => params, "type" => "debug"}

    message = %Message{
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
