defmodule LiveDebugger.LiveElements.View do
  defstruct [:id, :module, :assigns, :children]

  @type cid() :: integer() | nil

  @type t() :: %__MODULE__{
          id: String.t(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }
end
