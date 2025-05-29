defmodule LiveDebuggerWeb.Live.TracesLive.Hooks.TracingFuse do
  @moduledoc """
  This module provides a helper to manage tracing.
  It is responsible for determining if the tracing should be stopped.
  It introduces a fuse mechanism to prevent LiveView from being overloaded with traces.

  Required assigns:
  - `:lv_process` - the LiveView process
  - `:node_id` - the node ID
  - `:current_filters` - the current filters
  - `:trace_callback_running?` - whether the trace callback is running

  """

  import Phoenix.Component, only: [assign: 3]
  import LiveDebuggerWeb.Helpers
  import Phoenix.LiveView

  alias Phoenix.LiveView.Socket
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebuggerWeb.Hooks.Flash
  alias LiveDebugger.Utils.Parsers

  @assign_name :tracing_helper
  @time_period 1_000_000
  @trace_limit_per_period 100

  def trace_limit_per_period(), do: @trace_limit_per_period
  def time_period(), do: @time_period

  @spec init_hook(Socket.t()) :: Socket.t()
  def init_hook(socket) do
    socket
    |> check_assign(:lv_process)
    |> check_assign(:node_id)
    |> check_assign(:current_filters)
    |> check_assign(:trace_callback_running?)
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

  @spec maybe_disable_tracing_after_update(Socket.t()) :: Socket.t()
  def maybe_disable_tracing_after_update(socket) do
    if socket.assigns[@assign_name].tracing_started? do
      socket
    else
      clear_tracing(socket)
    end
  end

  @doc """
  Checks if the fuse is blown and stops tracing if it is.
  It uses the `#{@assign_name}` assign to store information.
  When tracing is not started returns `{:noop, socket}`.
  """
  @spec check_fuse(Socket.t()) :: {:ok | :stopped | :noop, Socket.t()}
  def check_fuse(%{assigns: %{@assign_name => %{tracing_started?: false}}} = socket) do
    {:noop, socket}
  end

  def check_fuse(%{assigns: %{@assign_name => %{tracing_started?: true}}} = socket) do
    fuse = socket.assigns[@assign_name].fuse

    cond do
      period_exceeded?(fuse) -> {:ok, reset_fuse(socket)}
      count_exceeded?(fuse) -> {:stopped, clear_tracing(socket)}
      true -> {:ok, increment_fuse(socket)}
    end
  end

  defp handle_info({:new_trace, _}, socket) do
    socket
    |> check_fuse()
    |> case do
      {:ok, socket} ->
        {:cont, socket}

      {:stopped, socket} ->
        limit = trace_limit_per_period()
        period = time_period() |> Parsers.parse_elapsed_time()

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

  defp check_assign(socket, assign_name) do
    if Map.has_key?(socket.assigns, assign_name) do
      socket
    else
      raise "Assign #{assign_name} is required by this hook: #{__MODULE__}"
    end
  end
end
