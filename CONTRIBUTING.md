# Contributing

If you are interested in contributing to LiveDebugger, please read this document.
We are happy to receive any feedback and contributions!

**NOTE:** LiveDebugger is no longer under active development, so we welcome any help.

## 1. Bugs

Before reporting a bug, check [existing bug reports][issues] first.
If nothing matches, open a [new bug report][bug-issue] and follow the template.

Bug fixes are always welcome!

## 2. Features

For new features, please check the [project board][project] and [discussions][discussions] to make sure your idea isn't already discussed.

- **Concrete feature?** Open a [feature request][feat-issue].
- **Broad idea or unsure?** Start a [discussion][discussions] first.

If you want to implement a feature, please wait for the issue to be accepted before starting a PR.

## 3. Architecture

LiveDebugger combines **services** that handle background work with an **app** that renders the UI in LiveView.
Tests are split between Elixir unit tests and TypeScript E2E tests.

Top-level layout:

```text
live_debugger/
├── assets/                  JS and CSS
├── dev/                     Example LiveView app used during development and testing
├── e2e/                     Playwright E2E tests
├── lib/live_debugger/
│   ├── api/                 Wrappers for modules mocked in tests and external APIs
│   ├── app/                 LiveView UI
│   └── services/            Background services
└── test/                    Elixir unit tests
```

### 3.1 Services

Each service has its own supervision tree and runs asynchronously.
Services shouldn't call each other directly - they communicate through the `LiveDebugger.Bus` module (PubSub) and exchange **events** (see `LiveDebugger.Event`).

Services interact with ETS, FileStorage, and the Phoenix.LiveView API through `api/` modules, which are mocked in tests.
Code that queries or aggregates data lives in `queries/`, code that changes data lives in `actions/`, and event handling lives in the GenServers.

Existing services:

- `callback_tracer` - traces LiveView callbacks in the debugged app.
- `client_communicator` - sends messages to the in-page client running inside the debugged app.
- `garbage_collector` - prunes stale entries from ETS tables.
- `process_monitor` - tracks LiveView processes in both the debugged app and LiveDebugger itself.
- `successor_discoverer` - finds the new process after a LiveView reconnects.
- `telemetry_handler` - listens for `:telemetry` events and forwards them.

For more details, see [`lib/live_debugger/services/README.md`](lib/live_debugger/services/README.md).

### 3.2 App

The LiveDebugger UI is written in LiveView.
Pages often consist of many components, nested LiveViews, hooks, and so on.
The file structure groups pages and their elements into subfolders to keep the code organized.

To avoid large files, split logic and components apart.
LiveDebugger uses `hooks` and `hook_components` to organize shared assigns.

For more details, see [`lib/live_debugger/app/README.md`](lib/live_debugger/app/README.md).

### 3.3 Unit tests

Every bug fix needs a regression test.
Every new feature needs proper test coverage.

CI runs the suite against two Elixir / OTP combinations: the latest and the oldest still supported. The exact versions are defined in [`.github/workflows/elixir-ci.yaml`](.github/workflows/elixir-ci.yaml). Don't use Elixir or LiveView features that aren't available in the oldest version.

For more details, see [`test/README.md`](test/README.md).

### 3.4 E2E tests

E2E tests use [Playwright][playwright].
They start the Dev application alongside LiveDebugger.

They might be flaky - if a failure looks unrelated to your change, rerun the suite.

For more details, see [`e2e/README.md`](e2e/README.md).

### 3.5 JS assets

- `assets/client` - runs inside the **debugged app**.
  Gathers info and draws overlays. Communicates with LiveDebugger through the `LiveDebugger.Client` module.
- `assets/app` - runs inside LiveDebugger. Holds LiveView hooks and styles for the UI.

Don't share modules between these two.

For more details, see [`assets/README.md`](assets/README.md).

## 4. Creating a pull request

Every PR should link to an existing issue. Use github generated branch names to make it easier.

### Local setup

Requirements:

- Elixir
- Node.js

The `.tool-versions` file lists the versions used for development - if you use [asdf](https://asdf-vm.com/), `asdf install` will pick them up automatically.

Clone the repo and run:

```console
mix setup
iex -S mix
```

This will fetch deps, handle JS and build assets before starting Dev application alongside LiveDebugger.

- Dev app: `http://localhost:4004`
- LiveDebugger: `http://localhost:4007`

LiveReload picks up `.ex` files and assets. If styles don't update, run:

```console
mix assets.build:dev
```

### Running tests

Set up E2E tests:

```console
mix e2e.setup
```

Run unit tests and E2E tests with:

```console
mix test
mix e2e
```

Some E2E tests can be flaky - rerun them if a failure looks unrelated to your change.

### Opening the PR

Before opening a PR please:

- Do a self review of your code.
- Ensure both unit tests (`mix test`) and E2E tests (`mix e2e`) pass.
- Run `mix format` and `mix credo` and fix any issues they report.
- Run `cd assets && npx prettier . --check` for the JS/CSS formatting check.
- Link to the related issue.

After creating the pull request please make sure CI passes! It runs the same checks against both the newest and the oldest supported Elixir/OTP versions.

---

Thanks for all the contributions and happy debugging!

[issues]: https://github.com/software-mansion/live-debugger/issues?q=is%3Aissue%20state%3Aopen%20label%3Abug
[bug-issue]: https://github.com/software-mansion/live-debugger/issues/new?template=bug_report.yaml
[feat-issue]: https://github.com/software-mansion/live-debugger/issues/new?template=feature_request.yaml
[discussions]: https://github.com/software-mansion/live-debugger/discussions
[project]: https://github.com/orgs/software-mansion/projects/42
[playwright]: https://playwright.dev/
