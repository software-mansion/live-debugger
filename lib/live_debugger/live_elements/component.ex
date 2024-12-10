defmodule LiveDebugger.LiveElements.Component do
  defstruct [:id, :cid, :module, :assigns, :children]

  import LiveDebugger.LiveElements.Common

  @type cid() :: integer() | nil

  @type t() :: %__MODULE__{
          id: String.t(),
          cid: cid(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }

  @type state_component() :: {integer(), {atom(), String.t(), map(), any(), any()}}

  @doc """
  Parses component from state.

  ## Example:
  ```elixir
  state = :sys.get_state(pid)
  {components, _, _} <- Map.get(state, :components) do
  Enum.map(components, fn component ->
    {:ok, live_component} = LiveDebugger.LiveElements.Component.parse(component)
    ...
  end
  ```
  """
  @spec parse(component :: state_component()) :: {:ok, t()} | {:error, term()}
  def parse({cid, {module, id, assigns, _, _}}) do
    {:ok,
     %__MODULE__{
       id: id,
       cid: cid,
       module: module,
       assigns: filter_assigns(assigns),
       children: []
     }}
  end

  def parse(_), do: {:error, :invalid_component}
end
