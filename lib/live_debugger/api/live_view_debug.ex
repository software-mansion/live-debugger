defmodule LiveDebugger.API.LiveViewDebug do
  @moduledoc """
  This module provides wrappers for Phoenix LiveView functions that are used for debugging a LiveView processes.
  """
  alias LiveDebugger.Structs.LvState

  @type lv() :: %{
          pid: pid(),
          view: module(),
          topic: String.t(),
          transport_pid: pid()
        }

  @callback list_liveviews() :: [lv()]
  @callback socket(pid()) :: {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}
  @callback live_components(pid()) :: {:ok, [LvState.component()]} | {:error, term()}

  @spec list_liveviews() :: [lv()]
  def list_liveviews() do
    impl().list_liveviews()
  end

  @spec socket(lv_pid :: pid()) :: {:ok, Phoenix.LiveView.Socket.t()} | {:error, term()}
  def socket(lv_pid) when is_pid(lv_pid) do
    impl().socket(lv_pid)
  end

  @spec live_components(lv_pid :: pid()) :: {:ok, [LvState.component()]} | {:error, term()}
  def live_components(lv_pid) when is_pid(lv_pid) do
    impl().live_components(lv_pid)
  end

  @spec liveview_state(lv_pid :: pid()) :: {:ok, LvState.t()} | {:error, term()}
  def liveview_state(lv_pid) when is_pid(lv_pid) do
    with {:ok, socket} <- socket(lv_pid),
         {:ok, components} <- live_components(lv_pid) do
      {:ok, %LvState{pid: lv_pid, socket: socket, components: components}}
    end
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_live_view_debug,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.LiveViewDebug

    if LiveDebugger.API.System.Module.loaded?(Phoenix.LiveView.Debug) do
      @impl true
      defdelegate list_liveviews(), to: Phoenix.LiveView.Debug
      @impl true
      defdelegate socket(pid), to: Phoenix.LiveView.Debug
      @impl true
      defdelegate live_components(pid), to: Phoenix.LiveView.Debug
    else
      alias LiveDebugger.API.System.Process, as: ProcessAPI

      @impl true
      def list_liveviews() do
        ProcessAPI.list()
        |> Enum.filter(&liveview?/1)
        |> Enum.map(fn pid ->
          case ProcessAPI.state(pid) do
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
        case ProcessAPI.state(pid) do
          {:ok, %{socket: %Phoenix.LiveView.Socket{} = socket}} -> {:ok, socket}
          _ -> {:error, :not_alive_or_not_a_liveview}
        end
      end

      @impl true
      def live_components(pid) do
        case ProcessAPI.state(pid) do
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

          _ ->
            {:error, :not_alive_or_not_a_liveview}
        end
      end

      @spec liveview?(pid :: pid()) :: boolean()
      defp liveview?(pid) do
        case ProcessAPI.initial_call(pid) do
          {:ok, {_module, :mount, _arity}} -> true
          _ -> false
        end
      end
    end
  end
end
