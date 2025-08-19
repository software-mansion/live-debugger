defmodule LiveDebugger.App.Debugger.Structs.TreeNode do
  @moduledoc """
  Structs and functions to build and manipulate the tree of LiveView and LiveComponent nodes.
  """

  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.Structs.LvState
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.CommonTypes

  defstruct [
    :id,
    :dom_id,
    :type,
    :module,
    :children
  ]

  @type id() :: pid() | CommonTypes.cid()
  @type type() :: :live_view | :live_component
  @type t() :: %__MODULE__{
          id: id(),
          dom_id: %{
            attribute: String.t(),
            value: String.t()
          },
          type: type(),
          module: module(),
          children: [t()]
        }

  defmodule Guards do
    @moduledoc "Guards for the TreeNode struct."
    defguard is_node_id(id) when is_pid(id) or is_struct(id, Phoenix.LiveComponent.CID)
  end

  @doc """
  Uses Parsers to convert the `id` field to the appropriate string representation.
  """
  @spec parse_id(t()) :: String.t()
  def parse_id(%__MODULE__{type: :live_view, id: pid}) when is_pid(pid) do
    Parsers.pid_to_string(pid)
  end

  def parse_id(%__MODULE__{type: :live_component, id: cid}) do
    Parsers.cid_to_string(cid)
  end

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
  Adds a child to the parent node.
  """
  @spec add_child(parent :: t(), child :: t()) :: t()
  def add_child(parent, child) do
    %{parent | children: parent.children ++ [child]}
  end

  @doc """
  Parses LiveView state to LiveDebugger.App.Debugger.Structs.TreeNode

  ## Examples

      iex> {:ok, state} = LiveDebugger.API.LiveViewDebug.liveview_state(pid)
      iex> LiveDebugger.App.Debugger.Structs.TreeNode.live_view_node(state)
      {:ok, %LiveDebugger.App.Debugger.Structs.TreeNode{...}}
  """
  @spec live_view_node(LvState.t()) :: {:ok, t()} | {:error, term()}
  def live_view_node(%LvState{pid: pid, socket: %{id: socket_id, view: view}}) do
    {:ok,
     %TreeNode{
       id: pid,
       dom_id: %{
         attribute: "id",
         value: socket_id
       },
       type: :live_view,
       module: view,
       children: []
     }}
  end

  def live_view_node(_), do: {:error, :invalid_lv_state}

  @doc """
  Parses `LvState` to a list of `LiveDebugger.App.Debugger.Structs.TreeNode` LiveComponent nodes.
  It doesn't include children.

  ## Examples

      iex> {:ok, state} = LiveDebugger.API.LiveViewDebug.liveview_state(pid)
      iex> LiveDebugger.App.Debugger.Structs.TreeNode.live_component_nodes(state)
      {:ok, [%LiveDebugger.App.Debugger.Structs.TreeNode{...}, ...]}
  """
  @spec live_component_nodes(LvState.t()) :: {:ok, [t()]} | {:error, term()}

  def live_component_nodes(%LvState{socket: %{id: socket_id}, components: components}) do
    Enum.reduce_while(components, {:ok, []}, fn component, acc ->
      case parse_channel_live_component(component, socket_id) do
        {:ok, component} ->
          {:ok, acc_components} = acc
          {:cont, {:ok, [component | acc_components]}}

        {:error, reason} ->
          {:halt, {:error, reason}}
      end
    end)
  end

  def live_component_nodes(_), do: {:error, :invalid_lv_state}

  @doc """
  Returns the type of the node based on the id.
  """
  @spec type(id()) :: type()
  def type(id) when is_pid(id), do: :live_view
  def type(%Phoenix.LiveComponent.CID{}), do: :live_component

  defp parse_channel_live_component(%{cid: integer_cid, module: module}, socket_id) do
    {:ok,
     %TreeNode{
       id: %Phoenix.LiveComponent.CID{cid: integer_cid},
       dom_id: %{
         attribute: "data-phx-id",
         value: "c#{integer_cid}-#{socket_id}"
       },
       type: :live_component,
       module: module,
       children: []
     }}
  end

  defp parse_channel_live_component(_, _), do: {:error, :invalid_live_component}
end
