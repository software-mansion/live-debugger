defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Hooks.TracingFuse do
  @moduledoc """
  This hook is responsible for handling the tracing fuse.
  It is used to handle the tracing fuse when the user starts tracing.
  It detects if the user is tracing too many callbacks in a short time and stops the tracing.
  """

  use LiveDebugger.App.Web, :hook

  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Hooks.Flash

  alias LiveDebugger.Bus
  alias LiveDebugger.Services.CallbackTracer.Events.TraceCalled
  alias LiveDebugger.Services.CallbackTracer.Events.TraceReturned
  alias LiveDebugger.Services.CallbackTracer.Events.TraceErrored

  @required_assigns [
    :lv_process,
    :parent_pid,
    :tracing_started?
  ]

  @time_period 1_000_000
  @trace_limit_per_period 100

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_hook!(:filter_new_traces)
    |> check_assigns!(@required_assigns)
    |> put_private(:fuse, nil)
    |> put_private(:trace_callback_running?, false)
    |> attach_hook(:tracing_fuse, :handle_info, &handle_info/2)
    |> register_hook(:tracing_fuse)
  end

  @doc """
  Switches the tracing state.
  """
  @spec switch_tracing(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def switch_tracing(socket) do
    if socket.assigns.tracing_started? do
      clear_tracing(socket)
    else
      start_tracing(socket)
    end
  end

  @doc """
  Disables the tracing.
  """
  @spec disable_tracing(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def disable_tracing(socket) do
    clear_tracing(socket)
  end

  @spec decrement_fuse(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def decrement_fuse(socket) do
    fuse = socket.private.fuse
    put_private(socket, :fuse, %{fuse | count: fuse.count - 1})
  end

  defp handle_info(%TraceCalled{}, socket) do
    socket
    |> check_fuse()
    |> case do
      {:ok, socket} ->
        socket
        |> put_private(:trace_callback_running?, true)
        |> cont()

      {:stopped, socket} ->
        socket
        |> push_tracing_stopped_flash()
        |> cont()

      {_, socket} ->
        {:halt, socket}
    end
  end

  defp handle_info(%TraceReturned{}, socket)
       when socket.private.trace_callback_running? do
    socket
    |> put_private(:trace_callback_running?, false)
    |> maybe_disable_tracing_after_update()
    |> cont()
  end

  defp handle_info(%TraceErrored{}, socket) when socket.private.trace_callback_running? do
    socket
    |> put_private(:trace_callback_running?, false)
    |> maybe_disable_tracing_after_update()
    |> cont()
  end

  defp handle_info(_, socket), do: {:cont, socket}

  defp push_tracing_stopped_flash(socket) do
    limit = @trace_limit_per_period
    period = @time_period |> Parsers.parse_elapsed_time()

    socket
    |> Flash.push_flash(
      :error,
      "Callback tracer stopped: Too many callbacks in a short time. Current limit is #{limit} callbacks in #{period}.",
      socket.assigns.parent_pid
    )
  end

  defp check_fuse(%{assigns: %{tracing_started?: false}} = socket) do
    {:noop, socket}
  end

  defp check_fuse(%{assigns: %{tracing_started?: true}} = socket) do
    fuse = socket.private.fuse

    cond do
      period_exceeded?(fuse) -> {:ok, reset_fuse(socket)}
      count_exceeded?(fuse) -> {:stopped, clear_tracing(socket)}
      true -> {:ok, increment_fuse(socket)}
    end
  end

  defp maybe_disable_tracing_after_update(socket) do
    if socket.assigns.tracing_started? do
      socket
    else
      clear_tracing(socket)
    end
  end

  defp period_exceeded?(fuse) do
    now() - fuse.start_time >= @time_period
  end

  defp count_exceeded?(fuse) do
    fuse.count + 1 >= @trace_limit_per_period
  end

  defp increment_fuse(socket) do
    fuse = socket.private.fuse
    put_private(socket, :fuse, %{fuse | count: fuse.count + 1})
  end

  defp reset_fuse(socket) do
    put_private(socket, :fuse, %{count: 0, start_time: now()})
  end

  defp start_tracing(socket) do
    if Phoenix.LiveView.connected?(socket) && socket.assigns[:lv_process] do
      Bus.receive_traces!(socket.assigns.lv_process.pid)
    end

    socket
    |> assign(:tracing_started?, true)
    |> put_private(:fuse, %{count: 0, start_time: now()})
  end

  defp clear_tracing(socket) do
    if Phoenix.LiveView.connected?(socket) && socket.assigns[:lv_process] &&
         not socket.private.trace_callback_running? do
      Bus.stop_receiving_traces(socket.assigns.lv_process.pid)
    end

    socket
    |> assign(:tracing_started?, false)
    |> put_private(:fuse, nil)
  end

  defp now() do
    :os.system_time(:microsecond)
  end
end
