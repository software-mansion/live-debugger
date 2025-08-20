defmodule LiveDebugger.App.Debugger.NodeState.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.NodeState` context.
  """

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.App.Debugger.Structs.TreeNode

  @spec fetch_node_assigns(pid :: pid(), node_id :: TreeNode.id()) ::
          {:ok, %{node_assigns: map()}} | {:error, term()}
  def fetch_node_assigns(pid, node_id) when is_pid(node_id) do
    case fetch_node_state(pid) do
      {:ok, %LvState{socket: %{assigns: assigns}}} ->
        {:ok, %{node_assigns: assigns}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_node_assigns(pid, %Phoenix.LiveComponent.CID{} = cid) do
    case fetch_node_state(pid) do
      {:ok, %LvState{components: components}} ->
        get_component_assigns(components, cid)

      {:error, reason} ->
        {:error, reason}
    end
  end

  def fetch_node_assigns(_, _) do
    {:error, "Invalid node ID"}
  end

  defp fetch_node_state(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end

  defp get_component_assigns(components, %Phoenix.LiveComponent.CID{cid: cid}) do
    components
    |> Enum.find(fn component -> component.cid == cid end)
    |> case do
      nil ->
        {:error, "Component with CID #{cid} not found"}

      component ->
        {:ok, %{node_assigns: component.assigns}}
    end
  end
end
