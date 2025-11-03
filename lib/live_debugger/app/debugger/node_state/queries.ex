defmodule LiveDebugger.App.Debugger.NodeState.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.NodeState` context.
  """

  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.App.Debugger.Structs.TreeNode

  alias LiveDebugger.API.TracesStorage

  alias LiveDebugger.App.Debugger.NodeState.StreamUtils

  @spec fetch_node_assigns(pid :: pid(), node_id :: TreeNode.id()) ::
          {:ok, map()} | {:error, term()}
  def fetch_node_assigns(pid, node_id) when is_pid(node_id) do
    case fetch_node_state(pid) do
      {:ok, %LvState{socket: %{assigns: assigns}}} ->
        {:ok, assigns}

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

  def fetch_node_streams(pid) do
    opts =
      [
        functions: ["render/1"]
      ]

    case TracesStorage.get!(pid, opts) do
      :end_of_table ->
        {:error, "No render traces found"}

      stream_updates ->
        StreamUtils.get_initial_stream_functions(stream_updates)
    end
  end

  def update_node_streams(_, stream_updates) do
    StreamUtils.get_stream_functions_from_updates([stream_updates])
  end

  defp get_component_assigns(components, %Phoenix.LiveComponent.CID{cid: cid}) do
    components
    |> Enum.find(fn component -> component.cid == cid end)
    |> case do
      nil ->
        {:error, "Component with CID #{cid} not found"}

      %{assigns: assigns} ->
        {:ok, assigns}
    end
  end
end
