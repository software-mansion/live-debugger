defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  if Mix.env() == :dev do
    def dev?(), do: true
  else
    def dev?(), do: false
  end

  def unit_test?() do
    Application.get_env(:live_debugger, :test_mode?, false) and
      not Application.get_env(:live_debugger, :e2e?, false)
  end

  def state_cache?() do
    Application.get_env(:live_debugger, :state_cache?, false)
  end
end
