defmodule LiveDebuggerRefactor.App.Debugger.Structs.TreeNode do
  @moduledoc """
  Structs and functions to build and manipulate the tree of LiveView and LiveComponent nodes.
  """

  alias LiveDebuggerRefactor.App.Utils.Parsers
  alias LiveDebuggerRefactor.CommonTypes

  defstruct [
    :id,
    :dom_id,
    :type,
    :module,
    :assigns,
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
          assigns: map(),
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
  Returns the type of the node based on the id.
  """
  @spec type(id()) :: type()
  def type(id) when is_pid(id), do: :live_view
  def type(%Phoenix.LiveComponent.CID{}), do: :live_component
end
