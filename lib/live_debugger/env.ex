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
  else
    def test?(), do: false
  end

  def unit_test?() do
    Application.get_env(:live_debugger, :test_mode?, false) and
      not Application.get_env(:live_debugger, :e2e?, false)
  end

  def dead_view_mode?() do
    Application.get_env(:live_debugger, :dead_view_mode?, false)
  end
end
