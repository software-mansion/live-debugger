defmodule LiveDebugger.Structs.TreeNode.LiveComponent do
  @moduledoc false

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
