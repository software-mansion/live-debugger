defmodule LiveDebugger.Helpers do
  @moduledoc false

  @spec ok(term()) :: {:ok, term()}
  def ok(state), do: {:ok, state}

  @spec noreply(term()) :: {:noreply, term()}
  def noreply(state), do: {:noreply, state}

  @spec cont(term()) :: {:cont, term()}
  def cont(state), do: {:cont, state}

  @spec halt(term()) :: {:halt, term()}
  def halt(state), do: {:halt, state}
end
