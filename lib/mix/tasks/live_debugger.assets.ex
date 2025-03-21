defmodule Mix.Tasks.LiveDebugger.Assets do
  @moduledoc "Generates assets from other deps"
  @shortdoc "Generates assets"

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
        --outdir=../priv/static/prod/
      ),
      cd: Path.expand("./live_debugger/priv/static", deps_path),
      env: %{"NODE_PATH" => deps_path}
    )

    Mix.Task.run("esbuild", ["live_debugger"]) |> IO.inspect()
  end
end
