# Inspiration was taken from Phoenix LiveDashboard
# https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/config/config.exs

import Config

if config_env() == :dev do
  config :esbuild,
    version: "0.18.6",
    default: [
      args: ~w(js/app.js --bundle --minify --sourcemap=external --target=es2020 --outdir=../dist),
      cd: Path.expand("../assets", __DIR__),
      env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
    ]
end
