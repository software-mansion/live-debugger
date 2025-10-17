# Used by "mix format"
[
  plugins: [Phoenix.LiveView.HTMLFormatter, Styler],
  inputs: ["{mix,.formatter,dev}.exs", "{config,lib,test,dev}/**/*.{ex,exs}"],
  migrate_eex_to_curly_interpolation: false
]
