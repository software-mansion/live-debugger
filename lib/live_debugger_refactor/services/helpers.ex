defmodule LiveDebuggerRefactor.Services.Helpers do
  @moduledoc false

  @type state() :: term()

  @spec ok(state()) :: {:ok, state()}
  def ok(state), do: {:ok, state}

  @spec noreply(state()) :: {:noreply, state()}
  def noreply(state), do: {:noreply, state}
end
