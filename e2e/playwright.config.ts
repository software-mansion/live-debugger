import { defineConfig, devices } from '@playwright/test';

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: './tests',
  /* Run tests in files in parallel */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only */
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 4 : undefined,
  maxFailures: process.env.CI ? 5 : undefined,
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: 'html',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('')`. */
    baseURL: 'http://localhost:4005',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    trace: 'on-first-retry',
  },

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
      testIgnore: '**/*.serial.spec.ts',
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      testIgnore: '**/*.serial.spec.ts',
    },
    {
      name: 'serial-tests chromium',
      use: { ...devices['Desktop Chrome'] },
      testMatch: '**/*.serial.spec.ts',
      dependencies: ['chromium', 'firefox'],
    },
    {
      name: 'serial-tests firefox',
      use: { ...devices['Desktop Firefox'] },
      testMatch: '**/*.serial.spec.ts',
      dependencies: ['chromium', 'firefox', 'serial-tests chromium'],
    },
  ],

  /* Run your local dev server before starting the tests */
  webServer: {
    command:
      'cd .. && MIX_ENV=test iex -e "Application.put_env(:live_debugger, :e2e?, true)" -S mix',
    url: 'http://localhost:4005',
    reuseExistingServer: !process.env.CI,
    stdout: 'pipe',
    env: {
      ELIXIR_EDITOR: '',
      EDITOR: '',
      TERM_PROGRAM: '',
    },
  },
});
