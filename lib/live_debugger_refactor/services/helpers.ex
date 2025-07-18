defmodule LiveDebuggerRefactor.Services.Helpers do
  @moduledoc false

  @spec ok(term()) :: {:ok, term()}
  def ok(state), do: {:ok, state}

  @spec noreply(term()) :: {:noreply, term()}
  def noreply(state), do: {:noreply, state}
end
