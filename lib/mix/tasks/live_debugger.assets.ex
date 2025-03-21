defmodule Mix.Tasks.LiveDebugger.Assets do
  @moduledoc """
  Task for generating assets for LiveDebugger
  This task is maent to be used in development only by users of `live_debugger` library.
  It generates assets from js files in other dependencies (`phoenix` and `phoenix_live_view`).
  """
  @shortdoc "Generates assets from other dependencies"

  use Mix.Task

  @impl true
  def run(_) do
    Mix.Task.run("esbuild.install", ["--if-missing"])
    deps_path = Mix.Project.deps_path() |> IO.inspect()

    Application.put_env(:esbuild, :version, "0.18.6")

    Application.put_env(:esbuild, :live_debugger,
      args: ~w(
        bundle/app.js
        --bundle
        --target=es2020
        --sourcemap=external
        --outfile=app.js
      ),
      cd: Path.expand("./live_debugger/priv/static", deps_path),
      env: %{"NODE_PATH" => deps_path}
    )

    Mix.Task.run("esbuild", ["live_debugger"])
  end
end
