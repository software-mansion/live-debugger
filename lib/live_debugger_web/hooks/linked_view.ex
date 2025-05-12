defmodule LiveDebuggerWeb.Hooks.LinkedView do
  @moduledoc """
    This hook should be used for views that are monitoring a debugged LiveView process.

    It assumes that the view is mounted with a `pid` param that identifies the LiveView process.
    It starts an async job to fetch the LiveView process via `lv_process` assign that is `AsyncResult` struct.
    - If the `lv_process` assign is not found, it will try to find a successor LiveView process and navigate to it.
    - If no successor is found, it will navigate to the error page.

    It also handles a case when the LiveView process dies by trying to find a successor LiveView process.

    The only thing you need to do after adding this hook is to handle loading state in the template.
    ## Example

    ```html
    <.async_result :let={lv_process} assign={@lv_process}>
      <:loading>
        <div class="m-auto flex items-center justify-center">
          <.spinner size="xl" />
        </div>
      </:loading>
      <!-- Loaded state -->
    </.async_result>
  ```
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
    |> attach_hook(:linked_view, :handle_async, &handle_async/3)
    |> attach_hook(:linked_view, :handle_info, &handle_info/2)
    |> start_async_assign_lv_process(string_pid)
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
    |> push_navigate(to: RoutesHelper.error("unexpected_error"))
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
      push_navigate(socket, to: RoutesHelper.channel_dashboard(successor_pid))
    else
      _ ->
        push_navigate(socket, to: RoutesHelper.error("not_found"))
    end
  end

  defp start_async_assign_lv_process(socket, string_pid) do
    case Parsers.string_to_pid(string_pid) do
      {:ok, pid} ->
        socket
        |> assign(:lv_process, AsyncResult.loading())
        |> start_async(:fetch_lv_process, fetch_lv_process_with_retries(pid))
        |> cont()

      :error ->
        socket
        |> push_navigate(to: RoutesHelper.error("invalid_pid"))
        |> halt()
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
