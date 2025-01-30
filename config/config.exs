# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.18.6",
    default: [
      args:
        ~w(js/app.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "3.4.3",
    live_debugger: [
      args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/app.css
      --minify
    ),
      cd: Path.expand("../assets", __DIR__)
    ]

  config :live_debugger, LiveDebugger.Endpoint,
    http: [port: 4007],
    secret_key_base: "Hu4qQN3iKzTV4fJxhorPQlA/osH9fAMtbtjVS58PFgfw3ja5Z18Q/WSNR9wP4OfW",
    live_view: [signing_salt: "your_signing_salt"],
    adapter: Bandit.PhoenixAdapter,
    debug_errors: true
end
