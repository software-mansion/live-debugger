defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  @env Mix.env()

  def dev?(), do: @env == :dev
end
