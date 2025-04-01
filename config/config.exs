# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.18.6",
    deploy_build: [
      args:
        ~w(js/hooks.js js/client.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    dev_build: [
      args:
        ~w(js/hooks.js js/client.js --bundle --sourcemap=external --target=es2020 --outdir=../priv/static/dev),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "3.4.17",
    deploy_build: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/app.css
      --minify
    ),
      cd: Path.expand("../assets", __DIR__)
    ],
    dev_build: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/dev/app.css
    ),
      cd: Path.expand("../assets", __DIR__)
    ]

  config :live_debugger,
    live_reload: [
      patterns: [
        ~r"priv/static/.*(js|css|svg)$",
        ~r"priv/static/dev/.*(js|css|svg)$"
      ]
    ]

  config :live_debugger, server: true

  config :live_debugger, browser_features?: true
end

if config_env() == :test do
  config :wallaby,
    driver: Wallaby.Chrome,
    otp_app: :live_debugger,
    chrome: [headless: true]

  config :live_debugger, server: true

  # Print only warnings and errors during test
  config :logger, level: :warning

  # Initialize plugs at runtime for faster test compilation
  config :phoenix, :plug_init_mode, :runtime

  config :phoenix_live_view,
    # Enable helpful, but potentially expensive runtime checks
    enable_expensive_runtime_checks: true
end
