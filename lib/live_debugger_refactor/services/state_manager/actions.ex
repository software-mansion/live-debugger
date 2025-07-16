defmodule LiveDebuggerRefactor.Services.StateManager.Actions do
  @moduledoc false

  @spec save_state(pid()) :: boolean()
  def save_state(pid) when is_pid(pid) do
    raise "Not implemented"
  end
end
