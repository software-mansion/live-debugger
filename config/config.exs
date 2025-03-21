# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

esbuild_version = "0.18.6"
dir_path = Path.expand("../assets", __DIR__)
node_path = Path.expand("../deps", __DIR__)

if config_env() == :dev do
  config :esbuild,
    version: esbuild_version,
    bundle_setup: [
      args: ~w(
        js/setup.js
        --bundle
        --minify
        --target=es2020
        --outdir=../priv/static/bundle/
        --format=esm
      ),
      cd: dir_path,
      env: %{"NODE_PATH" => node_path}
    ],
    bundle_app: [
      args: ~w(
        js/app.js
        --target=es2020
        --minify
        --outdir=../priv/static/bundle/
      ),
      cd: dir_path,
      env: %{"NODE_PATH" => node_path}
    ],
    deploy_build: [
      args:
        ~w(js/app.js js/client.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../priv/static/),
      cd: dir_path,
      env: %{"NODE_PATH" => node_path}
    ],
    dev_build: [
      args:
        ~w(js/app.js js/client.js --bundle --sourcemap=external --target=es2020 --outdir=../priv/static/dev),
      cd: dir_path,
      env: %{"NODE_PATH" => node_path}
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
