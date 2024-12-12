defmodule LiveDebugger.Service.TreeNode.LiveComponent do
  defstruct [:id, :cid, :module, :assigns, :children]

  @type cid() :: integer() | nil

  @type t() :: %__MODULE__{
          id: String.t(),
          cid: cid(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }
end
