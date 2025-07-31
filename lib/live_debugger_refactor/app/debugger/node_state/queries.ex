defmodule LiveDebuggerRefactor.App.Debugger.NodeState.Queries do
  @moduledoc """
  Queries for `LiveDebuggerRefactor.App.Debugger.NodeState` context.
  """

  alias LiveDebuggerRefactor.Structs.LvState
  alias LiveDebuggerRefactor.API.LiveViewDebug
  alias LiveDebuggerRefactor.API.StatesStorage
  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.App.Debugger.TreeNode

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
        {:error, "Component with CID #{Parsers.cid_to_string(cid)} not found"}

      component ->
        {:ok, %{node_assigns: component.assigns}}
    end
  end
end
