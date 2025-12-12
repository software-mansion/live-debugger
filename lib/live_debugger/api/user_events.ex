defmodule LiveDebugger.API.UserEvents do
  @moduledoc """
  API for sending user-triggered events and messages to LiveView processes.

  This module provides functions to interact with LiveView processes by sending
  various types of messages: component updates, info messages, GenServer casts/calls,
  and Phoenix LiveView events.
  """

  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveComponent.CID
  alias LiveDebugger.CommonTypes

  @callback send_component_update(LvProcess.t(), CommonTypes.cid(), map()) :: :ok
  @callback send_info_message(LvProcess.t(), term()) :: term()
  @callback send_genserver_cast(LvProcess.t(), term()) :: :ok
  @callback send_genserver_call(LvProcess.t(), term()) :: term()
  @callback send_lv_event(LvProcess.t(), CommonTypes.cid() | nil, String.t(), map()) :: term()

  @doc """
  Sends an update to a LiveComponent.

  This will trigger the `update_many/1` callback if defined, otherwise falls back to `update/2`.
  See: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html#module-update-many
  """
  @spec send_component_update(LvProcess.t(), CommonTypes.cid(), map()) :: :ok
  def send_component_update(%LvProcess{} = lv_process, %CID{} = cid, payload) do
    impl().send_component_update(lv_process, cid, payload)
  end

  @doc """
  Sends an info message directly to the LiveView process.

  The message will be handled by the `handle_info/2` callback in the LiveView.
  """
  @spec send_info_message(LvProcess.t(), term()) :: term()
  def send_info_message(%LvProcess{} = lv_process, payload) do
    impl().send_info_message(lv_process, payload)
  end

  @doc """
  Sends a GenServer cast to the LiveView process.

  The message will be handled by the `handle_cast/2` callback.
  """
  @spec send_genserver_cast(LvProcess.t(), term()) :: :ok
  def send_genserver_cast(%LvProcess{} = lv_process, payload) do
    impl().send_genserver_cast(lv_process, payload)
  end

  @doc """
  Sends a GenServer call to the LiveView process.

  The message will be handled by the `handle_call/3` callback.
  Returns the response from the LiveView process.
  """
  @spec send_genserver_call(LvProcess.t(), term()) :: term()
  def send_genserver_call(%LvProcess{} = lv_process, payload) do
    impl().send_genserver_call(lv_process, payload)
  end

  @doc """
  Sends a Phoenix LiveView event to the LiveView process.

  This simulates a user-triggered event (like a button click) and will be handled
  by the `handle_event/3` callback in the LiveView or LiveComponent.

  ## Parameters

    * `lv_process` - The target LiveView process
    * `cid` - Optional component ID (CID) if targeting a LiveComponent, `nil` for LiveView
    * `event` - The event name as a string
    * `params` - The event parameters as a map
  """
  @spec send_lv_event(LvProcess.t(), CommonTypes.cid() | nil, String.t(), map()) :: term()
  def send_lv_event(%LvProcess{} = lv_process, cid \\ nil, event, params) do
    impl().send_lv_event(lv_process, cid, event, params)
  end

  defp impl do
    Application.get_env(
      :live_debugger,
      :api_user_events,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.UserEvents

    alias LiveDebugger.Structs.LvProcess
    alias Phoenix.LiveComponent.CID

    @impl true
    def send_component_update(%LvProcess{} = lv_process, %CID{} = cid, payload) do
      Phoenix.LiveView.send_update(lv_process.pid, cid, payload)
    end

    @impl true
    def send_info_message(%LvProcess{} = lv_process, payload) do
      send(lv_process.pid, payload)
    end

    @impl true
    def send_genserver_cast(%LvProcess{} = lv_process, payload) do
      GenServer.cast(lv_process.pid, payload)
    end

    @impl true
    def send_genserver_call(%LvProcess{} = lv_process, payload) do
      GenServer.call(lv_process.pid, payload)
    end

    @impl true
    def send_lv_event(%LvProcess{} = lv_process, cid, event, params) do
      payload = %{"event" => event, "value" => params, "type" => "debug"}
      payload = if is_nil(cid), do: payload, else: Map.put(payload, "cid", cid.cid)

      message = %Phoenix.Socket.Message{
        topic: "lv:#{lv_process.socket_id}",
        event: "event",
        payload: payload
      }

      send(lv_process.pid, message)
    end
  end
end
