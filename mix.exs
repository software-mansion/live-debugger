defmodule LiveDebugger.MixProject do
  use Mix.Project

  @version "0.4.3"

  def project do
    [
      app: :live_debugger,
      version: @version,
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      aliases: aliases(),
      package: package(),
      name: "LiveDebugger",
      source_url: "https://github.com/software-mansion/live-debugger",
      description: "Tool for debugging LiveView applications",
      docs: docs(),
      test_coverage: [
        ignore_modules: [~r/^LiveDebuggerDev\./, DevWeb]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {LiveDebugger, []}
    ]
  end

  def cli() do
    [preferred_envs: [e2e: :test]]
  end

  defp elixirc_paths(:dev), do: ["lib", "dev"]

  defp elixirc_paths(:test),
    do: ["lib", "dev", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: [
        "deps.get",
        "cmd --cd assets/app npm install",
        "cmd --cd assets/client npm install",
        "assets.setup",
        "assets.build:dev"
      ],
      test: ["test --exclude e2e"],
      e2e: [&e2e_tests_setup/1, "test --only e2e"],
      "assets.setup": ["esbuild.install --if-missing", "tailwind.install --if-missing"],
      "assets.build:deploy": [
        "esbuild build_app_js_deploy",
        "esbuild build_client_js_deploy",
        "esbuild build_client_css_deploy",
        "tailwind build_app_css_deploy"
      ],
      "assets.build:dev": [
        "esbuild build_app_js_dev",
        "esbuild build_client_js_dev",
        "esbuild build_client_css_dev",
        "tailwind build_app_css_dev"
      ]
    ]
  end

  defp e2e_tests_setup(_) do
    Application.put_env(:live_debugger, :e2e?, true)
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix_live_view, "~> 0.20.8 or ~> 1.0"},
      {:phoenix, "~> 1.7"},
      {:igniter, "~> 0.5 and >= 0.5.40", optional: true},
      {:bandit, "~> 1.6", only: [:dev, :test]},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:esbuild, "~> 0.7", only: :dev},
      {:tailwind, "~> 0.3", only: :dev},
      {:mox, "~> 1.2", only: :test},
      {:phx_new, "~> 1.7", only: :test},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:wallaby, "~> 0.30", runtime: false, only: :test}
    ]
  end

  defp docs() do
    [
      main: "welcome",
      logo: "./docs/images/logo.png",
      extra_section: "GUIDES",
      extras: [
        "CHANGELOG.md",
        "docs/welcome.md": [title: "Welcome to LiveDebugger"],
        "docs/features.md": [title: "Features Overview"],
        "docs/config.md": [title: "Configuration"],
        "docs/components_tree.md": [title: "Components Tree"],
        "docs/assigns_inspection.md": [title: "Assigns Inspection"],
        "docs/callback_tracing.md": [title: "Callback Tracing"],
        "docs/components_highlighting.md": [title: "Components Highlighting"],
        "docs/dead_view_mode.md": [title: "DeadView Mode"],
        "docs/elements_inspection.md": [title: "Elements Inspection"]
      ],
      groups_for_extras: [
        Features: [
          "docs/features.md",
          "docs/assigns_inspection.md",
          "docs/components_tree.md",
          "docs/callback_tracing.md",
          "docs/components_highlighting.md",
          "docs/dead_view_mode.md",
          "docs/elements_inspection.md"
        ]
      ],
      source_url: "https://github.com/software-mansion/live-debugger",
      source_ref: @version,
      api_reference: false,
      assets: %{
        Path.expand("./docs/images") => "images"
      },
      filter_modules: fn module, _meta ->
        module == Mix.Tasks.LiveDebugger.Install
      end
    ]
  end

  defp package do
    [
      licenses: ["Apache-2.0"],
      links: %{
        changelog: "https://hexdocs.pm/live_debugger/changelog.html",
        github: "https://github.com/software-mansion/live-debugger"
      },
      files: ~w(lib priv LICENSE mix.exs README.md CHANGELOG.md)
    ]
  end
end
