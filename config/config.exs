# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

esbuild_version = "0.18.6"

if config_env() == :dev do
  config :esbuild,
    version: esbuild_version,
    deploy_build: [
      args: ~w(
        js/app.js
        js/client.js
        --bundle
        --minify
        --sourcemap=external
        --target=es2020
        --outdir=../priv/static/
        --alias:phoenix_default=phoenix
        --alias:phoenix_html_default=phoenix_html
        --alias:phoenix_live_view_default=phoenix_live_view
      ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ],
    dev_build: [
      args: ~w(
        js/app.js
        js/client.js
        --bundle
        --minify
        --sourcemap=external
        --target=es2020
        --outdir=../priv/static/dev/
        --alias:phoenix_default=phoenix
        --alias:phoenix_html_default=phoenix_html
        --alias:phoenix_live_view_default=phoenix_live_view
      ),
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
else
  config :esbuild,
    version: esbuild_version,
    build: [
      args: ~w(
        js/app.js
        js/client.js
        --bundle
        --minify
        --sourcemap=external
        --target=es2020
        --outdir=../priv/static/
        --alias:phoenix_dep=phoenix
        --alias:phoenix_html_dep=phoenix_html
        --alias:phoenix_live_view_dep=phoenix_live_view
      ),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../../", __DIR__)}
    ]
end
