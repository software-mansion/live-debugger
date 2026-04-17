defmodule LiveDebugger.App.Web.Hooks.TracerStatus do
  @moduledoc """
  This hook manages the tracing status and handles the case when the tracer crashes.
  It listens for `DbgKilled` messages and updates the `:tracing_status` assign accordingly.
  """

  use LiveDebugger.App.Web, :hook

  alias LiveDebugger.Services.CallbackTracer.GenServers.TracingManager
  alias Phoenix.LiveView.AsyncResult

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.DbgKilled
  alias LiveDebugger.Services.CallbackTracer.Events.DbgStarted

  require Logger

  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    if connected?(socket) do
      Bus.receive_events!()
    end

    socket
    |> attach_hook(:tracer_status, :handle_info, &handle_info/2)
    |> attach_hook(:tracer_status, :handle_async, &handle_async/3)
    |> register_hook(:tracer_status)
    |> assign(:tracer_started?, AsyncResult.loading())
    |> start_async(:tracer_started?, fn -> tracer_status() end)
  end

  @spec refresh_tracer_status() :: :ok
  def refresh_tracer_status() do
    send(self(), {:tracer_status, :refetch})
    :ok
  end

  defp handle_info(%DbgKilled{}, socket) do
    {:halt, assign(socket, :tracer_started?, AsyncResult.ok(false))}
  end

  defp handle_info(%DbgStarted{}, socket) do
    {:halt, assign(socket, :tracer_started?, AsyncResult.ok(true))}
  end

  defp handle_info({:tracer_status, :refetch}, socket) do
    socket
    |> assign(:tracer_started?, AsyncResult.loading())
    |> start_async(:tracer_started?, fn -> tracer_status() end)
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp handle_async(:tracer_started?, {:ok, started?}, socket) do
    {:halt, assign(socket, :tracer_started?, AsyncResult.ok(started?))}
  end

  defp handle_async(:tracer_started?, {:exit, {:timeout, _}}, socket) do
    tracer_started? = socket.assigns.tracer_started?

    {:halt, assign(socket, :tracer_started?, AsyncResult.failed(tracer_started?, :timeout))}
  end

  defp handle_async(:tracer_started?, _, socket) do
    tracer_started? = socket.assigns.tracer_started?

    Logger.error("Failed to get tracer status")

    {:halt, assign(socket, :tracer_started?, AsyncResult.failed(tracer_started?, :error))}
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  defp tracer_status() do
    %{:dbg_pid => dbg_pid} = GenServer.call(TracingManager, :get_state, 10_000)
    dbg_pid != nil
  end
end
