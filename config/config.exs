# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.18.6",
    build_app_js_deploy: [
      args:
        ~w(app.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../../priv/static/),
      cd: Path.expand("../assets/app", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    build_client_js_deploy: [
      args:
        ~w(client.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../../priv/static --loader:.html=text),
      cd: Path.expand("../assets/client", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    build_client_css_deploy: [
      args: ~w(client.css --bundle --sourcemap=external --minify --outdir=../../priv/static/),
      cd: Path.expand("../assets/client", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    build_app_js_dev: [
      args:
        ~w(app.js --bundle --sourcemap=external --target=es2020 --outdir=../../priv/static/dev),
      cd: Path.expand("../assets/app", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    build_client_js_dev: [
      args:
        ~w(client.js --bundle --sourcemap=external --target=es2020 --outdir=../../priv/static/dev --loader:.html=text),
      cd: Path.expand("../assets/client", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    build_client_css_dev: [
      args: ~w(client.css --bundle --sourcemap=external --outdir=../../priv/static/dev),
      cd: Path.expand("../assets/client", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "4.1.8",
    build_app_css_deploy: [
      args: ~w(
      --input=assets/app/app.css
      --output=priv/static/app.css
      --minify
    ),
      cd: Path.expand("..", __DIR__)
    ],
    build_app_css_dev: [
      args: ~w(
      --input=assets/app/app.css
      --output=priv/static/dev/app.css
    ),
      cd: Path.expand("..", __DIR__)
    ]

  config :live_debugger,
    live_reload: [
      patterns: [
        ~r"priv/static/.*(js|css|svg)$",
        ~r"priv/static/dev/.*(js|css|svg)$",
        ~r"lib/live_debugger_web/.*ex$"
      ]
    ]

  config :live_debugger, LiveDebugger.App.Web.Endpoint, debug_errors: true

  config :live_debugger, update_checks?: false

  config :phoenix_live_view, enable_expensive_runtime_checks: true
end

if config_env() == :test do
  config :wallaby,
    driver: Wallaby.Chrome,
    otp_app: :live_debugger,
    chrome: [headless: true],
    js_logger: nil,
    screenshot_on_failure: true,
    screenshot_dir: "tmp/screenshots",
    max_wait_time: 5_000

  config :live_debugger,
    server: true,
    port: 4008

  config :live_debugger, update_checks?: false

  # Print only warnings and errors during test
  config :logger, level: :warning

  # Initialize plugs at runtime for faster test compilation
  config :phoenix, :plug_init_mode, :runtime
end
