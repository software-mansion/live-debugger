defmodule LiveDebugger.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_debugger,
      version: "0.0.1",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install", "assets.build"],
      dev: "run --no-halt dev.exs",
      "assets.build": ["esbuild default --minify"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 1.0"},
      {:esbuild, "~> 0.7", only: :dev},
      {:phoenix_playground, "~> 0.1.7", only: :dev}
    ]
  end
end
