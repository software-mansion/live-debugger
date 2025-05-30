defmodule LiveDebuggerWeb.Hooks.TracesLiveView.TracingFuse do
  @moduledoc """
  This hook is responsible for managing the tracing fuse.
  It is responsible for determining if the tracing should be stopped.
  It introduces a fuse mechanism to prevent LiveView from being overloaded with traces.
  It also handles the case when the trace callback is running.

  This hook has to be added before IncomingTraces hook.

  Required assigns (that are used somehow in the hook):
  - `:lv_process` - the LiveView process
  - `:node_id` - the node ID
  - `:current_filters` - the current filters
  - `:root_pid` - the root PID
  - `:trace_callback_running?` - whether the trace callback is running
  """

  import Phoenix.Component, only: [assign: 3]
  import LiveDebuggerWeb.Helpers
  import Phoenix.LiveView
  import LiveDebuggerWeb.Helpers.TracesLiveViewHelper

  alias Phoenix.LiveView.Socket
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Hooks.Flash
  alias LiveDebugger.Utils.Parsers

  @assign_name :tracing_helper
  @time_period 1_000_000
  @trace_limit_per_period 100

  @spec init_hook(Socket.t()) :: Socket.t()
  def init_hook(socket) do
    socket
    |> check_assign!(:lv_process)
    |> check_assign!(:node_id)
    |> check_assign!(:current_filters)
    |> check_assign!(:trace_callback_running?)
    |> check_assign!(:root_pid)
    |> attach_hook(:tracing_helper, :handle_info, &handle_info/2)
    |> clear_tracing()
  end

  @spec switch_tracing(Socket.t()) :: Socket.t()
  def switch_tracing(socket) do
    if socket.assigns[@assign_name].tracing_started? do
      clear_tracing(socket)
    else
      start_tracing(socket)
    end
  end

  @spec disable_tracing(Socket.t()) :: Socket.t()
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

        socket.assigns.root_pid
        |> Flash.push_flash(
          socket,
          "Callback tracer stopped: Too many callbacks in a short time. Current limit is #{limit} callbacks in #{period}."
        )
        |> halt()

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
    if socket.assigns[@assign_name].tracing_started? do
      socket
    else
      clear_tracing(socket)
    end
  end

  defp check_fuse(%{assigns: %{@assign_name => %{tracing_started?: false}}} = socket) do
    {:noop, socket}
  end

  defp check_fuse(%{assigns: %{@assign_name => %{tracing_started?: true}}} = socket) do
    fuse = socket.assigns[@assign_name].fuse

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
    fuse = socket.assigns[@assign_name].fuse

    assigns = %{
      tracing_started?: true,
      fuse: %{fuse | count: fuse.count + 1}
    }

    assign(socket, @assign_name, assigns)
  end

  defp reset_fuse(socket) do
    assigns = %{
      tracing_started?: true,
      fuse: %{count: 0, start_time: now()}
    }

    assign(socket, @assign_name, assigns)
  end

  defp start_tracing(socket) do
    assigns = %{
      tracing_started?: true,
      fuse: %{count: 0, start_time: now()}
    }

    if Phoenix.LiveView.connected?(socket) && socket.assigns[:lv_process] do
      socket
      |> get_active_topics()
      |> PubSubUtils.subscribe!()
    end

    assign(socket, @assign_name, assigns)
  end

  defp clear_tracing(socket) do
    assigns = %{
      tracing_started?: false,
      fuse: nil
    }

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

    assign(socket, @assign_name, assigns)
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
