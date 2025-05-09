defmodule LiveDebuggerWeb.Hooks.LinkedView do
  @moduledoc """
  Hook to handle linked views.
  """

  require Logger

  import Phoenix.LiveView
  import LiveDebuggerWeb.Helpers
  import Phoenix.Component

  alias LiveDebugger.Structs.LvProcess
  alias Phoenix.LiveView.AsyncResult

  alias LiveDebugger.Services.LiveViewDiscoveryService
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  defmacro __using__(_opts) do
    quote do
      on_mount({LiveDebuggerWeb.Hooks.LinkedView, :add_hook})
    end
  end

  def on_mount(:add_hook, %{"pid" => string_pid}, _session, socket) do
    socket
    |> start_async_assign_lv_process(string_pid)
    |> attach_hook(:linked_view, :handle_async, &handle_async/3)
    |> attach_hook(:linked_view, :handle_info, &handle_info/2)
    |> cont()
  end

  # When fetching LvProcess fails, we try to find a successor LvProcess
  def handle_async(:fetch_lv_process, {:ok, nil}, socket) do
    socket
    |> handle_liveview_process_not_found()
    |> halt()
  end

  # When fetching LvProcess succeeds, we subscribe to its process state
  def handle_async(:fetch_lv_process, {:ok, fetched_lv_process}, socket) do
    subscribe_process_state(fetched_lv_process.pid)

    socket
    |> assign(:lv_process, AsyncResult.ok(fetched_lv_process))
    |> halt()
  end

  # When fetching LvProcess fails, we assign the error to the socket
  def handle_async(:fetch_lv_process, {:exit, reason}, socket) do
    Logger.error(
      "LiveDebugger encountered unexpected error while fetching information for process: #{inspect(reason)}"
    )

    socket
    |> assign(
      :lv_process,
      AsyncResult.failed(socket.assigns.lv_process, reason)
    )
    |> halt()
  end

  def handle_async(_, _, socket), do: {:cont, socket}

  def handle_info({:process_status, :dead}, socket) do
    socket
    |> handle_liveview_process_not_found()
    |> halt()
  end

  def handle_info(_, socket), do: {:cont, socket}

  defp handle_liveview_process_not_found(socket) do
    with %{lv_process: %{result: %LvProcess{} = lv_process}} <- socket.assigns,
         %{pid: successor_pid} <-
           fetch_with_retries(fn -> LiveViewDiscoveryService.successor_lv_process(lv_process) end) do
      socket
      |> push_navigate(to: RoutesHelper.channel_dashboard(successor_pid))
    else
      _ ->
        result = %AsyncResult{
          ok?: false,
          loading: nil,
          failed: :not_found,
          result: nil
        }

        socket
        |> assign(:lv_process, result)
    end
  end

  defp start_async_assign_lv_process(socket, string_pid) do
    case Parsers.string_to_pid(string_pid) do
      {:ok, pid} ->
        socket
        |> assign(:lv_process, AsyncResult.loading())
        |> start_async(:fetch_lv_process, fetch_lv_process_with_retries(pid))

      :error ->
        assign(
          socket,
          :lv_process,
          AsyncResult.failed(AsyncResult.loading(), :invalid_transport_pid)
        )
    end
  end

  defp fetch_lv_process_with_retries(pid) do
    fn -> fetch_with_retries(fn -> LiveViewDiscoveryService.lv_process(pid) end) end
  end

  defp fetch_with_retries(function) do
    with nil <- fetch_after(function, 200),
         nil <- fetch_after(function, 800) do
      fetch_after(function, 1000)
    end
  end

  defp subscribe_process_state(pid) do
    pid
    |> PubSubUtils.process_status_topic()
    |> PubSubUtils.subscribe!()
  end

  defp fetch_after(function, milliseconds) do
    Process.sleep(milliseconds)
    function.()
  end
end
