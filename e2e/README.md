# E2E Tests

End-to-end tests for LiveDebugger using [Playwright](https://playwright.dev/).

## Setup

```sh
mix e2e.setup
```

## Running

```sh
mix e2e
# Or via `npx` in the `e2e/` folder:
npx playwright test --ui
npx playwright test --quiet --retries 2
```

Reports land in `e2e/playwright-report/` — open with `npx playwright show-report`.

## Global setup

`global-setup.ts` runs once before the suite. It opens the dev app + debugger and verifies the `TracingManager` initializes asynchronously after boot.

## Conventions

- Use `*.serial.spec.ts` naming when a test mutates global state (settings, tracer config) that other tests would race on.
- Prefer `getByRole`, `getByText`, `locator` over CSS selectors when possible.
