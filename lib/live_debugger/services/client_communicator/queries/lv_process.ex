defmodule LiveDebugger.Services.ClientCommunicator.Queries.LvProcess do
  @moduledoc """
  Queries for LiveView processes.
  """

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Structs.LvState

  alias LiveDebugger.API.LiveViewDiscovery
  alias LiveDebugger.API.LiveViewDebug

  @spec get_by_socket_id(String.t()) :: {:ok, LvProcess.t()} | :not_found
  def get_by_socket_id(socket_id) do
    LiveViewDiscovery.debugged_lv_processes()
    |> Enum.filter(fn lv_process -> lv_process.socket_id == socket_id end)
    |> case do
      [lv_process] -> {:ok, lv_process}
      _ -> :not_found
    end
  end

  @spec get_live_component(LvProcess.t(), non_neg_integer()) ::
          {:ok, LvState.component()} | :not_found
  def get_live_component(lv_process, cid) do
    lv_process.pid
    |> LiveViewDebug.live_components()
    |> case do
      {:ok, components} ->
        find_component_by_cid(components, cid)

      {:error, _} ->
        :not_found
    end
  end

  defp find_component_by_cid(components, cid) do
    case Enum.find(components, fn component -> component.cid == cid end) do
      nil -> :not_found
      component -> {:ok, component}
    end
  end
end
