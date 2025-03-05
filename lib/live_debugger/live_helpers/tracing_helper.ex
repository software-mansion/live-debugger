defmodule LiveDebugger.LiveHelpers.TracingHelper do
  @moduledoc """
  This module provides a helper to manage tracing.
  It is responsible for determining if the tracing should be stopped.
  It introduces a fuse mechanism to prevent LiveView from being overloaded with traces.
  """

  import Phoenix.Component, only: [assign: 3]

  alias Phoenix.LiveView.Socket

  @assign_name :tracing_helper
  @time_period 1_000_000
  @trace_limit_per_period 100

  @spec init(Socket.t()) :: Socket.t()
  def init(socket) do
    stop_tracing(socket)
  end

  @spec switch_tracing(Socket.t()) :: Socket.t()
  def switch_tracing(socket) do
    case socket.assigns[@assign_name].tracing_started? do
      true -> stop_tracing(socket)
      false -> start_tracing(socket)
    end
  end

  @spec check_fuse(Socket.t()) :: {:ok, Socket.t()} | {:stopped, Socket.t()}
  def check_fuse(%{assigns: %{@assign_name => %{tracing_started?: false}}} = socket) do
    {:stopped, socket}
  end

  def check_fuse(%{assigns: %{@assign_name => %{tracing_started?: true}}} = socket) do
    fuse = socket.assigns[@assign_name].fuse

    cond do
      period_exceeded?(fuse) -> {:ok, reset_fuse(socket)}
      count_exceeded?(fuse) -> {:stopped, stop_tracing(socket)}
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

    assign(socket, @assign_name, assigns)
  end

  def stop_tracing(socket) do
    assigns = %{
      tracing_started?: false,
      fuse: nil
    }

    assign(socket, @assign_name, assigns)
  end

  defp now() do
    :os.system_time(:microsecond)
  end
end
