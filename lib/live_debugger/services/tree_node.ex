defmodule LiveDebugger.Services.TreeNode do
  @doc """
  This module provides functions to work with the tree of LiveView and LiveComponent nodes (TreeNodes).
  """
  alias LiveDebugger.Services.TreeNode.LiveView, as: LiveViewNode
  alias LiveDebugger.Services.TreeNode.LiveComponent, as: LiveComponentNode

  @type t() :: LiveViewNode.t() | LiveComponentNode.t()
  @type id() :: integer() | pid()
  @typedoc """
  Value of channel_state's `socket` field.
  """
  @type channel_state_socket() :: %{id: String.t(), root_pid: pid(), view: atom(), assigns: map()}
  @typedoc """
  A key-value pair from channel_state's `components` map
  """
  @type channel_state_component() ::
          {cid :: integer(), {module :: atom(), id :: String.t(), assigns :: map(), any(), any()}}

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
  Parses state's socket to LiveDebugger.Services.TreeNode.LiveView.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScrapper.channel_state_from_pid(pid)
      iex> LiveDebugger.Services.TreeNode.live_view_node(state.socket)
      {:ok, %LiveDebugger.Services.TreeNode.LiveView{...}}
  """
  @spec live_view_node(socket :: channel_state_socket()) :: {:ok, t()} | {:error, term()}
  def live_view_node(socket)

  def live_view_node(%{id: id, root_pid: pid, view: view, assigns: assigns}) do
    {:ok,
     %LiveViewNode{
       id: id,
       pid: pid,
       module: view,
       assigns: assigns,
       children: []
     }}
  end

  def live_view_node(_), do: {:error, :invalid_view}

  @doc """
  Parses component from state to LiveDebugger.Services.TreeNode.LiveComponent.

  ## Examples

      iex> {:ok, state} = LiveDebugger.Services.LiveViewScrapper.channel_state_from_pid(pid)
      iex> {components, _, _} <- Map.get(state, :components) do
      iex> Enum.map(components, fn component ->
      ...> {:ok, live_component} = live_component_node(component)
      ...> end
      [
        {:ok, %LiveDebugger.Services.TreeNode.LiveComponent{...}},
        {:ok, %LiveDebugger.Services.TreeNode.LiveComponent{...}}
      ]
  """
  @spec live_component_node(component :: channel_state_component()) ::
          {:ok, t()} | {:error, term()}
  def live_component_node(component)

  def live_component_node({cid, {module, id, assigns, _, _}}) do
    {:ok,
     %LiveComponentNode{
       id: id,
       cid: cid,
       module: module,
       assigns: assigns,
       children: []
     }}
  end

  def live_component_node(_), do: {:error, :invalid_component}
end
