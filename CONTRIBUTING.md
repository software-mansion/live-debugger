# Contributing
 
If you are interested in contributing to LiveDebugger please read this document.
We are happy to receive any feedback and contribution!

## 1. Bugs

Before reporting a bug check [existing issues][issues] first.
If nothing matches, open a [new bug report][bug-issue] and follow the template.

Bug fixes are always welcome.
Browse open [issues][issues] and comment on the one you want to take.

## 2. Features

New new features please check [project board][project] and [discussions][discussions] to make sure your idea isn't already discussed.


- **Concrete feature?** Open a [feature request][feat-issue].
- **Broad idea or unsure?** Start a [discussion][discussions] first.

Wait for an issue to be accepted before starting a PR.

## 3. Creating a pull requests

Every PR should link to an existing issue.

### Local setup

Clone repo and execute

```console
mix setup
iex -S mix
```

This setups work environment and runs LiveDebugger and example `Dev` aplication. 

- `Dev` app: `http://localhost:4004`
- LiveDebugger: `http://localhost:4007`

LiveReload handles `.ex` files and assets. If styles don't update, run:

```console
mix assets.build:dev
```

### Running tests

For E2E tests you need to setup them with `mix e2e.setup`.

There are unit tests and E2E test wich can be run using 

```console
mix test
mix e2e
```
Some E2E tests might be flaky so you can rerun them if needed.

### Before pushing

- Run `mix test` and `mix e2e`.
- Run `mix format`

### Opening the PR

- Link the issue.
- Keep it focused on one change.
- Make sure CI is green (unit tests across Elixir versions, E2E, formatter).


## 3. Architecture

LiveDebugger consists of background **services**, a **LiveView UI**, **unit tests**, **E2E tests**, and **JS assets**.
Read through `lib/live_debugger/` and `assets/` before making non-trivial changes - the layout has strong conventions and matching them makes review faster.

### 3.1 Services

Each service has its own supervision tree and runs asynchronously.
Services shouldn't call each other directly — they communicate via the `Bus` module (PubSub) and exchange **events** (see `lib/live_debugger/event.ex`).

Services are interacting with ETS, FileStorage and Phoenix.LiveView api for debugging via `api/` modules.
Logic for querying and aggregating data should be inside `queries/`, modyfing data inside `actions/` and event handling inside GenServer.

### 3.2 App

The UI is built from LiveViews, sometimes nested, that subscribe to events.

Common practices inside project.
- For shared-state UI components, check `hook_components/`.
- Don't grow files indefinitely. Split logic into `hooks`, presentation into
  components, live components or nested LiveViews (which suit heavy message passing cases)

### 3.3 Unit tests

- Every bug fix needs a regression test.
- Every new feature needs proper test coverage.
- CI runs the suite against multiple Elixir versions - don't use Elixr and LiveView features which are not supported in earliest versions.


### 3.4 E2E tests

E2E tests use [Playwright][playwright].
They spawn the `dev` application alongside LiveDebugger.

E2E tests can be flaky — if a failure looks unrelated to your change, rerun the suite.

### 3.5 JS assets

- **`assets/client`** — runs inside the **debugged app**.
Gathers info and draws overlays. It communicates with LiveDebugger via `lib/live_debugger/client/`
- **`assets/app`** — runs inside **LiveDebugger**.
LiveView hooks and styles for the UI.

Don't share modules between the two.

### Thanks for all the contributions and happy debugging!

[issues]: https://github.com/software-mansion/live-debugger/issues?q=is%3Aissue%20state%3Aopen%20label%3Abug
[bug-issue]: https://github.com/software-mansion/live-debugger/issues/new?template=bug_report.yaml
[feat-issue]: https://github.com/software-mansion/live-debugger/issues/new?template=feature_request.yaml
[discussions]: https://github.com/software-mansion/live-debugger/discussions
[project]: https://github.com/orgs/software-mansion/projects/42
[playwright]: https://playwright.dev/
