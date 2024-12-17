defmodule LiveDebugger.Services.TreeNode.LiveView do
  defstruct [:id, :pid, :module, :assigns, :children]

  @type t() :: %__MODULE__{
          id: String.t(),
          pid: pid(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }
end
