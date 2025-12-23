defmodule LiveDebugger.App.Debugger.NodeState.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.NodeState` context.
  """

  alias LiveDebugger.API.TracesStorage
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.API.LiveViewDebug
  alias LiveDebugger.API.StatesStorage
  alias LiveDebugger.App.Debugger.Structs.TreeNode

  @type history_index :: non_neg_integer()
  @type history_length :: non_neg_integer()
  @type history_entries :: {assigns1 :: map(), assigns2 :: map()} | {assigns :: map()}

  @spec fetch_node_assigns(pid(), TreeNode.id()) :: {:ok, map()} | {:error, term()}
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

  @spec fetch_assigns_history_entries(pid(), TreeNode.id(), history_index()) ::
          {:ok, {history_entries(), history_length()}} | {:error, term()}
  def fetch_assigns_history_entries(pid, node_id, index) do
    case TracesStorage.get!(pid, functions: ["render/1"], node_id: node_id) do
      :end_of_table ->
        {:error, :no_history_record}

      {render_traces, _} ->
        history_length = length(render_traces)
        index = min(index, history_length - 1)

        result =
          render_traces
          |> Enum.slice(index, 2)
          |> Enum.map(&(&1.args |> hd() |> Map.delete(:socket)))

        {:ok, {result, history_length}}
    end
  rescue
    error -> {:error, error}
  end

  @spec fetch_node_temporary_assigns(pid(), TreeNode.id()) :: {:ok, map()} | {:error, term()}
  def fetch_node_temporary_assigns(pid, node_id) do
    with {:ok, node_assigns} <- fetch_last_render_assigns(pid, node_id),
         %{temporary_assigns: temporary_assigns} <- node_assigns.socket.private do
      {:ok, Map.take(node_assigns, Map.keys(temporary_assigns))}
    else
      {:error, error} -> {:error, error}
      _ -> {:error, :no_temporary_assigns}
    end
  end

  defp fetch_node_state(pid) do
    case StatesStorage.get!(pid) do
      nil -> LiveViewDebug.liveview_state(pid)
      state -> {:ok, state}
    end
  end

  defp fetch_last_render_assigns(pid, node_id) do
    case TracesStorage.get!(pid, node_id: node_id, functions: ["render/1"], limit: 1) do
      :end_of_table ->
        {:error, :no_render_trace}

      {[%{args: [node_assigns]}], _} ->
        {:ok, node_assigns}
    end
  rescue
    error -> {:error, error}
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
