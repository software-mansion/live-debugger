defmodule Mix.Tasks.LiveDebugger.Assets do
  @moduledoc "Generates assets from other deps"
  @shortdoc "Generates assets"

  use Mix.Task

  @impl true
  def run(_) do
    Mix.Task.run("esbuild.install", ["--if-missing"])
    deps_path = Mix.Project.deps_path() |> IO.inspect()
  end
end
