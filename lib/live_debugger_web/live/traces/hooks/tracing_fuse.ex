defmodule LiveDebuggerWeb.Live.Traces.Hooks.TracingFuse do
  @moduledoc """
  This hook is responsible for handling the tracing fuse.
  It is used to handle the tracing fuse when the user starts tracing.
  It detects if the user is tracing too many callbacks in a short time and stops the tracing.
  """

  use LiveDebuggerWeb, :hook

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Hooks.Flash
  alias LiveDebugger.Utils.Parsers

  @time_period 1_000_000
  @trace_limit_per_period 100

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(:lv_process)
    |> check_assigns!(:node_id)
    |> check_assigns!(:current_filters)
    |> check_assigns!(:trace_callback_running?)
    |> check_assigns!(:parent_pid)
    |> check_assigns!(:tracing_started?)
    |> put_private(:fuse, nil)
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

  defp handle_info({:new_trace, _}, socket) do
    socket
    |> check_fuse()
    |> case do
      {:ok, socket} ->
        {:cont, socket}

      {:stopped, socket} ->
        limit = @trace_limit_per_period
        period = @time_period |> Parsers.parse_elapsed_time()

        socket.assigns.parent_pid
        |> Flash.push_flash(
          socket,
          "Callback tracer stopped: Too many callbacks in a short time. Current limit is #{limit} callbacks in #{period}."
        )
        |> cont()

      {_, socket} ->
        {:halt, socket}
    end
  end

  defp handle_info({:updated_trace, _}, socket) when socket.assigns.trace_callback_running? do
    socket
    |> maybe_disable_tracing_after_update()
    |> cont()
  end

  defp handle_info(_, socket) do
    {:cont, socket}
  end

  defp maybe_disable_tracing_after_update(socket) do
    if socket.assigns.tracing_started? do
      socket
    else
      clear_tracing(socket)
    end
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

  defp period_exceeded?(fuse) do
    now() - fuse.start_time >= @time_period
  end

  defp count_exceeded?(fuse) do
    fuse.count + 1 >= @trace_limit_per_period
  end

  defp increment_fuse(socket) do
    fuse = socket.private.fuse

    socket
    |> assign(:tracing_started?, true)
    |> put_private(:fuse, %{fuse | count: fuse.count + 1})
  end

  defp reset_fuse(socket) do
    socket
    |> assign(:tracing_started?, true)
    |> put_private(:fuse, %{count: 0, start_time: now()})
  end

  defp start_tracing(socket) do
    if Phoenix.LiveView.connected?(socket) && socket.assigns[:lv_process] do
      socket
      |> get_active_topics()
      |> PubSubUtils.subscribe!()
    end

    socket
    |> assign(:tracing_started?, true)
    |> put_private(:fuse, %{count: 0, start_time: now()})
  end

  defp clear_tracing(socket) do
    if Phoenix.LiveView.connected?(socket) && socket.assigns[:lv_process] do
      socket
      |> get_topics(:call)
      |> PubSubUtils.unsubscribe()

      if not socket.assigns.trace_callback_running? do
        socket
        |> get_topics(:return)
        |> PubSubUtils.unsubscribe()
      end
    end

    socket
    |> assign(:tracing_started?, false)
    |> put_private(:fuse, nil)
  end

  defp now() do
    :os.system_time(:microsecond)
  end

  defp get_active_topics(socket) do
    lv_process = socket.assigns.lv_process
    node_id = socket.assigns.node_id

    socket.assigns.current_filters.functions
    |> Enum.filter(fn {_, active?} -> active? end)
    |> Enum.flat_map(fn {function, _} ->
      [
        PubSubUtils.trace_topic_per_node(
          lv_process.pid,
          node_id,
          function,
          :call
        ),
        PubSubUtils.trace_topic_per_node(
          lv_process.pid,
          node_id,
          function,
          :return
        )
      ]
    end)
  end

  defp get_topics(socket, type) do
    lv_process = socket.assigns.lv_process
    node_id = socket.assigns.node_id

    socket.assigns.current_filters.functions
    |> Enum.map(fn {function, _} ->
      PubSubUtils.trace_topic_per_node(
        lv_process.pid,
        node_id,
        function,
        type
      )
    end)
  end
end
