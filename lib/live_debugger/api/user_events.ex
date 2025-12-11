defmodule LiveDebugger.API.UserEvents do
  @moduledoc """
  API for user events.
  """

  defguard is_cid(cid) when is_struct(cid, Phoenix.LiveComponent.CID)

  def send_event(pid, cid \\ nil, handler_type, payload)

  def send_event(pid, cid, :update, payload) when is_pid(pid) and is_cid(cid) do
    Phoenix.LiveView.send_update(pid, cid, payload)
  end

  def send_event(pid, nil, :handle_info, payload) when is_pid(pid) do
    send(pid, payload)
  end

  def send_event(pid, nil, :handle_cast, payload) when is_pid(pid) do
    GenServer.cast(pid, payload)
  end

  def send_event(pid, nil, :handle_call, payload) when is_pid(pid) do
    GenServer.call(pid, payload)
  end
end
