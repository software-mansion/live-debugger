defmodule LiveDebugger.Services.LiveViewService do
  @moduledoc """
  This module provides wrappers for Phoenix LiveView functions that are used for debugging a LiveView processes.
  """
  @type lv() :: %{
          pid: pid(),
          view: module(),
          topic: String.t(),
          transport_pid: pid()
        }

  @callback list_liveviews() :: [lv()]
  @callback socket(pid()) :: Phoenix.LiveView.Socket.t()
  @callback live_components(pid()) :: [map()]

  @spec list_liveviews() :: [lv()]
  def list_liveviews() do
    impl().list_liveviews()
  end

  @spec socket(pid()) :: Phoenix.LiveView.Socket.t()
  def socket(lv_pid) do
    impl().socket(lv_pid)
  end

  @spec live_components(pid()) :: [map()]
  def live_components(lv_pid) do
    impl().live_components(lv_pid)
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :liveview_service,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Services.LiveViewService

    if LiveDebugger.Services.System.ModuleService.loaded?(Phoenix.LiveView.Debug) do
      @impl true
      defdelegate list_liveviews(), to: Phoenix.LiveView.Debug
      @impl true
      defdelegate socket(pid), to: Phoenix.LiveView.Debug
      @impl true
      defdelegate live_components(pid), to: Phoenix.LiveView.Debug
    else
      alias LiveDebugger.Services.System.ProcessService

      @impl true
      def list_liveviews() do
        ProcessService.list()
        |> Enum.filter(fn pid -> ProcessService.initial_call(pid) |> liveview?() end)
        |> Enum.map(fn pid ->
          case LiveDebugger.Services.System.ProcessService.state(pid) do
            {:ok, %{socket: socket, topic: topic}} ->
              %{
                pid: pid,
                view: socket.view,
                topic: topic,
                transport_pid: socket.transport_pid
              }

            {:error, _} ->
              nil
          end
        end)
        |> Enum.reject(&is_nil/1)
      end

      @impl true
      def socket(pid) do
        case LiveDebugger.Services.System.ProcessService.state(pid) do
          {:ok, %{socket: socket}} -> {:ok, socket}
          {:error, _} -> {:error, :not_alive_or_not_a_liveview}
        end
      end

      @impl true
      def live_components(pid) do
        case LiveDebugger.Services.System.ProcessService.state(pid) do
          {:ok, %{components: {components, _, _}}} ->
            component_info =
              Enum.map(components, fn {cid, {mod, id, assigns, private, _prints}} ->
                %{
                  id: id,
                  cid: cid,
                  module: mod,
                  assigns: assigns,
                  children_cids: private.children_cids
                }
              end)

            {:ok, component_info}

          {:error, _} ->
            {:error, :not_alive_or_not_a_liveview}
        end
      end

      @spec liveview?(initial_call :: mfa() | nil | {}) :: boolean()
      defp liveview?(initial_call) when initial_call not in [nil, {}] do
        elem(initial_call, 1) == :mount
      end

      defp liveview?(_), do: false
    end
  end
end
