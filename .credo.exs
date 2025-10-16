%{
  configs: [
    %{
      name: "live_debugger",
      files: %{
        included: ["lib/live_debugger/**/*.ex", "test/**/*.exs"],
        excluded: []
      },
      plugins: [],
      requires: [],
      strict: true,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [

        ]
      }
    }
  ]
}
