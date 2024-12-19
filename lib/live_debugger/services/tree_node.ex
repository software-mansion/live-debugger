defmodule LiveDebugger.Services.TreeNode do
  @doc """
  This module provides functions to work with the tree of LiveView and LiveComponent nodes (TreeNodes).
  """
  alias LiveDebugger.Services.TreeNode.LiveView, as: LiveViewNode
  alias LiveDebugger.Services.TreeNode.LiveComponent, as: LiveComponentNode

  @type t() :: LiveViewNode.t() | LiveComponentNode.t()
  @type cid() :: integer()
  @type id() :: cid() | pid()
  @typedoc """
  Value of channel_state's `socket` field.
  """
  @type channel_state_socket() :: %{id: String.t(), root_pid: pid(), view: atom(), assigns: map()}
  @typedoc """
  A key-value pair from channel_state's `components` map
  """
  @type channel_state_component() ::
          {cid :: cid(), {module :: atom(), id :: String.t(), assigns :: map(), any(), any()}}

  @type channel_state() :: %{
          socket: channel_state_socket(),
          components: {%{cid() => channel_state_component()}, any(), any()}
        }

  @spec add_child(parent :: t(), child :: t()) :: t()
  def add_child(parent, child) do
    %{parent | children: parent.children ++ [child]}
  end

  @spec get_child(parent :: t(), child_id :: id()) :: t() | nil
  def get_child(parent, child_id)

  def get_child(parent, child_cid) when is_integer(child_cid) do
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
  Parses channel_state to LiveDebugger.Services.TreeNode.LiveView.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScraper.channel_state_from_pid(pid)
      iex> LiveDebugger.Services.TreeNode.live_view_node(state)
      {:ok, %LiveDebugger.Services.TreeNode.LiveView{...}}
  """
  @spec live_view_node(channel_state :: channel_state()) :: {:ok, t()} | {:error, term()}
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
  Parses channel_state state to LiveDebugger.Services.TreeNode.LiveComponent of given CID.
  If the component is not found, returns `nil`.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScraper.channel_state_from_pid(pid)
      iex> LiveDebugger.Services.TreeNode.live_component_node(state, 2)
      {:ok, %LiveDebugger.Services.TreeNode.LiveComponent{cid: 2, ...}}

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScraper.channel_state_from_pid(pid)
      iex> LiveDebugger.Services.TreeNode.live_component_node(state, 999)
      {:ok, nil}
  """
  @spec live_component_node(channel_state :: channel_state(), cid :: cid()) ::
          {:ok, t() | nil} | {:error, term()}
  def live_component_node(channel_state, cid)

  def live_component_node(%{components: {components_map, _, _}}, cid) do
    components_map
    |> Enum.find(fn {component_cid, _} -> component_cid == cid end)
    |> case do
      nil ->
        {:ok, nil}

      channel_live_component ->
        parse_channel_live_component(channel_live_component)
    end
  end

  def live_component_node(_, _), do: {:error, :invalid_channel_state}

  @doc """
  Parses channel_state to a list of all LiveDebugger.Services.TreeNode.LiveComponent nodes

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.get_channel_state(pid)
      iex> LiveDebugger.Services.TreeNode.live_component_nodes(state)
      {:ok, [%LiveDebugger.Services.TreeNode.LiveComponent{...}, ...]}
  """
  @spec live_component_nodes(channel_state :: channel_state()) :: {:ok, [t()]} | {:error, term()}
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

  defp parse_channel_live_component({cid, {module, id, assigns, _, _}}) do
    {:ok,
     %LiveComponentNode{
       id: id,
       cid: cid,
       module: module,
       assigns: assigns,
       children: []
     }}
  end

  defp parse_channel_live_component(_), do: {:error, :invalid_channel_component}
end
