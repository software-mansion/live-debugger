defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  @env Mix.env()

  # This is to avoid dialyzer warning
  # Dialyzer uses :test as env always, and it gives a warning that == cannot be true
  @dialyzer {:no_match, dev?: 0}

  def dev?(), do: @env == :dev

  def unit_test?() do
    Application.get_env(:live_debugger, :test_mode?, false) and
      not Application.get_env(:live_debugger, :e2e?, false)
  end
end
