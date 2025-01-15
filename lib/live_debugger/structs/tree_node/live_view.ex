defmodule LiveDebugger.Structs.TreeNode.LiveView do
  @moduledoc """
  This module provides a struct to represent a LiveView in the tree.
  """

  defstruct [:id, :pid, :module, :assigns, :children]

  @type t() :: %__MODULE__{
          id: String.t(),
          pid: pid(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }
end
