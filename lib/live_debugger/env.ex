defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  if Mix.env() == :dev do
    def dev?(), do: true
  else
    def dev?(), do: false
  end

  if Mix.env() == :test do
    def test?(), do: true

    def unit_test?(), do: not Application.get_env(:live_debugger, :e2e?, false)
  else
    def test?(), do: false

    def unit_test?(), do: false
  end
end
