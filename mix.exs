defmodule LiveDebugger.MixProject do
  use Mix.Project

  def project do
    [
      app: :live_debugger,
      version: "0.0.2",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install", "assets.setup", "assets.build"],
      dev: "run --no-halt dev.exs",
      "assets.setup": ["esbuild.install --if-missing", "tailwind.install --if-missing"],
      "assets.build": ["esbuild default --minify", "tailwind live_debugger --minify"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.20 or ~> 1.0"},
      {:bandit, "~> 1.6", only: :dev},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:esbuild, "~> 0.7", only: :dev},
      {:tailwind, "~> 0.2", only: :dev},
      {:mox, "~> 1.2", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:phoenix_live_dashboard, "~> 0.7"}
    ]
  end
end
