defmodule LiveDebugger.LiveHelpers.TracingHelper do
  @moduledoc """
  This module provides a helper to manage tracing.
  It is responsible for determining if the tracing should be stopped.
  It introduces a fuse mechanism to prevent LiveView from being overloaded with traces.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Phoenix.LiveView.Socket
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils

  @assign_name :tracing_helper
  @time_period 1_000_000
  @trace_limit_per_period 100

  @spec init(Socket.t()) :: Socket.t()
  def init(socket) do
    clear_tracing(socket)
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
    start_tracing(socket)
  end

  defp start_tracing(socket) do
    assigns = %{
      tracing_started?: true,
      fuse: %{count: 0, start_time: now()}
    }

    if Phoenix.LiveView.connected?(socket) do
      PubSubUtils.subscribe(socket.assigns.trace_topic)
    end

    assign(socket, @assign_name, assigns)
  end

  defp clear_tracing(socket) do
    assigns = %{
      tracing_started?: false,
      fuse: nil
    }

    if Phoenix.LiveView.connected?(socket) do
      PubSubUtils.unsubscribe(socket.assigns.trace_topic)
    end

    assign(socket, @assign_name, assigns)
  end

  defp now() do
    :os.system_time(:microsecond)
  end
end
