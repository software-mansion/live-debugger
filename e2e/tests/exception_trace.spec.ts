import { test as base, expect, Page } from '@playwright/test';

const test = base
  .extend<{ devApp: Page }>({
    devApp: async ({ page }, use) => {
      await page.goto('/');
      await use(page);
    },
  })
  .extend<{ dbgApp: Page }>({
    dbgApp: async ({ devApp }, use) => {
      await devApp.locator('#live-debugger-debug-button').click();
      const dbgAppPromise = devApp.waitForEvent('popup');
      await devApp.getByText('Open in new tab').click();
      const dbgApp = await dbgAppPromise;
      await use(dbgApp);
    },
  });

const findTraces = (page: Page) =>
  page.locator('#global-traces-stream details');

const findSwitchTracingButton = (page: Page) =>
  page.locator('button[phx-click="switch-tracing"]');

const findClearTracesButton = (page: Page) =>
  page.locator('button[phx-click="clear-traces"]');

const findGlobalCallbackTracesButton = (page: Page) =>
  page.locator('#global-traces-navbar-item a');

const findErrorButton = (page: Page, action: string) =>
  page.locator(`button[phx-click="${action}"]`);

test('debugger captures runtime errors and exceptions in global callbacks', async ({
  devApp,
  dbgApp,
}) => {
  await findGlobalCallbackTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();

  testException(
    devApp,
    dbgApp,
    'crash_argument',
    'ArgumentError',
    'invalid_integer'
  );
});

const testException = async (
  devApp: Page,
  dbgApp: Page,
  crashName: string,
  errorName: string,
  stacktraceContent: string
) => {
  await findErrorButton(devApp, crashName).click();

  // TODO: assert trace exception
};
