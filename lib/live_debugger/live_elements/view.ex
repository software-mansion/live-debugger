defmodule LiveDebugger.LiveElements.View do
  defstruct [:id, :module, :assigns, :children]

  import LiveDebugger.LiveElements.Common

  @type cid() :: integer() | nil

  @type t() :: %__MODULE__{
          id: String.t(),
          module: atom(),
          assigns: map(),
          children: [t()]
        }

  @type state_view() :: %{id: String.t(), view: atom(), assigns: map()}

  @doc """
  Parses component from state's socket

  ## Example:
  ```elixir
  state = :sys.get_state(pid)
  {:ok, live_view} = LiveDebugger.LiveElements.View.parse(state.socket)
  ```
  """
  @spec parse(view :: state_view()) :: {:ok, t()} | {:error, term()}
  def parse(%{id: id, view: view, assigns: assigns}) do
    {:ok,
     %__MODULE__{
       id: id,
       module: view,
       assigns: filter_assigns(assigns),
       children: []
     }}
  end

  def parse(_), do: {:error, :invalid_view}
end
