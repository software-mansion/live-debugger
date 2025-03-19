defmodule Mix.Tasks.LiveDebugger.Assets.Build do
  @moduledoc "Generates assets from other deps"
  @shortdoc "Generates assets"

  use Mix.Task

  @impl true
  def run(_) do
    Mix.Task.run("esbuild", ["build"])
  end
end
