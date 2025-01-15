defmodule LiveDebugger.Structs.TreeNode do
  @moduledoc """
  This module provides functions to work with the tree of LiveView and LiveComponent nodes (TreeNodes).
  """

  alias LiveDebugger.Utils.Parsers
  alias LiveDebugger.Structs.TreeNode.LiveView, as: LiveViewNode
  alias LiveDebugger.Structs.TreeNode.LiveComponent, as: LiveComponentNode
  alias LiveDebugger.CommonTypes

  @type t() :: LiveViewNode.t() | LiveComponentNode.t()
  @type cid() :: LiveComponentNode.cid()
  @type id() :: cid() | pid()

  @doc """
  Returns PID or CID of the node.
  """
  @spec id(node :: t()) :: id()
  def id(%LiveViewNode{pid: pid} = _node), do: pid
  def id(%LiveComponentNode{cid: cid}), do: cid

  @doc """
  Gives type of the node.
  Types:
    * `:live_view`
    * `:live_component`
  """
  @spec type(node :: t()) :: atom()
  def type(%LiveViewNode{}), do: :live_view
  def type(%LiveComponentNode{}), do: :live_component

  @doc """
  Returns string representation of the node's ID, ready to be displayed in the UI.
  """
  @spec display_id(node :: t()) :: String.t()
  def display_id(%LiveViewNode{pid: pid}), do: Parsers.pid_to_string(pid)
  def display_id(%LiveComponentNode{cid: cid}), do: Parsers.cid_to_string(cid)

  @doc """
  Parses ID from string to PID or CID.
  """
  @spec id_from_string(id :: String.t()) :: {:ok, id()} | :error
  def id_from_string(id) when is_binary(id) do
    with :error <- Parsers.string_to_pid(id) do
      Parsers.string_to_cid(id)
    end
  end

  @doc """
  Same as `id_from_string/1`, but raises an ArgumentError if the ID is invalid.
  """
  @spec id_from_string!(id :: String.t()) :: id()
  def id_from_string!(string) do
    case id_from_string(string) do
      {:ok, id} -> id
      :error -> raise ArgumentError, "Invalid ID: #{inspect(string)}"
    end
  end

  @doc """
  Adds a child to the parent node.
  """
  @spec add_child(parent :: t(), child :: t()) :: t()
  def add_child(parent, child) do
    %{parent | children: parent.children ++ [child]}
  end

  @doc """
  Returns a child of the parent node by PID or CID.
  """
  @spec get_child(parent :: t(), child_id :: id()) :: t() | nil
  def get_child(parent, child_id)

  def get_child(parent, child_cid) when is_struct(child_cid) do
    Enum.find(parent.children, fn
      %LiveComponentNode{cid: cid} -> cid == child_cid
      _ -> false
    end)
  end

  def get_child(parent, child_pid) when is_pid(child_pid) do
    Enum.find(parent.children, fn
      %LiveViewNode{pid: pid} -> pid == child_pid
      _ -> false
    end)
  end

  @doc """
  Parses channel_state to LiveDebugger.Structs.TreeNode.LiveView.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewDiscoveryService.channel_state_from_pid(pid)
      iex> LiveDebugger.Structs.TreeNode.live_view_node(state)
      {:ok, %LiveDebugger.Structs.TreeNode.LiveView{...}}
  """
  @spec live_view_node(channel_state :: CommonTypes.channel_state()) ::
          {:ok, t()} | {:error, term()}
  def live_view_node(channel_state)

  def live_view_node(%{socket: %{id: id, root_pid: pid, view: view, assigns: assigns}}) do
    {:ok,
     %LiveViewNode{
       id: id,
       pid: pid,
       module: view,
       assigns: assigns,
       children: []
     }}
  end

  def live_view_node(_), do: {:error, :invalid_channel_view}

  @doc """
  Parses channel_state state to LiveDebugger.Structs.TreeNode.LiveComponent of given CID.
  If the component is not found, returns `nil`.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewDiscoveryService.channel_state_from_pid(pid)
      iex> LiveDebugger.Structs.TreeNode.live_component_node(state, 2)
      {:ok, %LiveDebugger.Structs.TreeNode.LiveComponent{cid: 2, ...}}

      iex> {:ok, state} = LiveDebugger.Services.LiveViewDiscoveryService.channel_state_from_pid(pid)
      iex> LiveDebugger.Structs.TreeNode.live_component_node(state, 999)
      {:ok, nil}
  """
  @spec live_component_node(channel_state :: CommonTypes.channel_state(), cid :: cid()) ::
          {:ok, t() | nil} | {:error, term()}
  def live_component_node(channel_state, cid)

  def live_component_node(%{components: {components_map, _, _}}, cid) do
    components_map
    |> Enum.find(fn {integer_cid, _} -> integer_cid == cid.cid end)
    |> case do
      nil ->
        {:ok, nil}

      channel_live_component ->
        parse_channel_live_component(channel_live_component)
    end
  end

  def live_component_node(_, _), do: {:error, :invalid_channel_state}

  @doc """
  Parses channel_state to a list of all LiveDebugger.Structs.TreeNode.LiveComponent nodes.
  It doesn't include children.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.get_channel_state(pid)
      iex> LiveDebugger.Structs.TreeNode.live_component_nodes(state)
      {:ok, [%LiveDebugger.Structs.TreeNode.LiveComponent{...}, ...]}
  """
  @spec live_component_nodes(channel_state :: CommonTypes.channel_state()) ::
          {:ok, [t()]} | {:error, term()}
  def live_component_nodes(channel_state)

  def live_component_nodes(%{components: {components_map, _, _}}) do
    Enum.reduce_while(components_map, {:ok, []}, fn channel_component, acc ->
      case parse_channel_live_component(channel_component) do
        {:ok, component} ->
          {:ok, acc_components} = acc
          {:cont, {:ok, [component | acc_components]}}

        {:error, _} ->
          {:halt, {:error, :invalid_channel_component}}
      end
    end)
  end

  def live_component_nodes(_), do: {:error, :invalid_channel_state}

  defp parse_channel_live_component({integer_cid, {module, id, assigns, _, _}}) do
    {:ok,
     %LiveComponentNode{
       id: id,
       cid: %Phoenix.LiveComponent.CID{cid: integer_cid},
       module: module,
       assigns: assigns,
       children: []
     }}
  end

  defp parse_channel_live_component(_), do: {:error, :invalid_channel_component}
end
