# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.18.6",
    deploy_build: [
      args:
        ~w(js/app.js js/client.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    dev_build: [
      args:
        ~w(js/app.js js/client.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/dev),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]

  config :tailwind,
    version: "3.4.3",
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
      --minify
    ),
      cd: Path.expand("../assets", __DIR__)
    ]

  config :live_debugger, browser_features?: true
end
