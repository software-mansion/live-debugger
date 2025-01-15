defmodule LiveDebugger.Structs.TreeNode.LiveComponent do
  @moduledoc """
  This module provides a struct to represent a LiveComponent in the tree.
  """

  defstruct [:id, :cid, :module, :assigns, :children]

  @type cid() :: %Phoenix.LiveComponent.CID{cid: integer()}

  @type t() :: %__MODULE__{
          id: String.t(),
          cid: cid(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }
end
