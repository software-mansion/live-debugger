defmodule LiveDebugger.MixProject do
  use Mix.Project

  @version "0.1.4"

  def project do
    [
      app: :live_debugger,
      version: @version,
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      package: package(),
      name: "LiveDebugger",
      source_url: "https://github.com/software-mansion/live-debugger",
      description: "Tool for debugging LiveView applications",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {LiveDebugger, []}
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: ["deps.get", "cmd --cd assets npm install", "assets.setup", "assets.build:dev"],
      dev: "run --no-halt dev.exs",
      "assets.setup": ["esbuild.install --if-missing", "tailwind.install --if-missing"],
      "assets.build:deploy": ["esbuild deploy_build", "tailwind deploy_build"],
      "assets.build:dev": ["esbuild dev_build", "tailwind dev_build"]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.20 or ~> 1.0"},
      {:igniter, "~> 0.5 and >= 0.5.40", optional: true},
      {:bandit, "~> 1.6", only: :dev},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:esbuild, "~> 0.7", only: :dev},
      {:tailwind, "~> 0.2", only: :dev},
      {:mox, "~> 1.2", only: :test},
      {:phx_new, "~> 1.7", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md", "LICENSE"],
      source_url: "https://github.com/software-mansion/live-debugger",
      source_ref: @version
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{github: "https://github.com/software-mansion/live-debugger"},
      files: ~w(lib priv LICENSE mix.exs README.md)
    ]
  end
end
