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
end
