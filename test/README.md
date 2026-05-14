# Tests

Unit tests for the LiveDebugger Elixir code. Layout mirrors `lib/` (e.g. `lib/foo/bar.ex` → `test/foo/bar_test.exs`).

## Running

```sh
mix test                          # full suite
mix test test/services            # subdir
mix test test/path/to/file.exs:42 # single test by line
```

## Writing a test

### Helpers

- `test/support/fakes.ex` - provides reusable factory functions (build a fake `LvProcess`, `Trace`, etc.)
- `test_helper.exs` - test suite entry script; defines shared mocks

### Conventions

- Use `async: true` whenever the test does not touch global state (most tests).
- Use `Fakes` rather than constructing structs by hand — keeps fields consistent across tests.
