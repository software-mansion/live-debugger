defmodule Mix.Tasks.E2e do
  use Mix.Task

  @impl true
  def run(_) do
    IO.puts("-- elo --")

    LiveDebuggerDev.Runner.run()
  end
end
