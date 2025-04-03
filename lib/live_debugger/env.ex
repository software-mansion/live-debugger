defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  if Mix.env() == :dev do
    def dev?(), do: true
  else
    def dev?(), do: false
  end
end
