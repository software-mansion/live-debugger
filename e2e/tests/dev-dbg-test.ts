import { test as base, Page } from '@playwright/test';

export const test = base
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

export const assigns_entry = (page: Page, key: string, value: string) =>
  page.locator(
    `xpath=//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"${key}:\")]/../..//*[contains(normalize-space(text()), \"${value}\")]`
  );

export const findTraces = (page: Page) =>
  page.locator('#traces-list-stream details');

export const findSwitchTracingButton = (page: Page) =>
  page.locator('button[phx-click="switch-tracing"]');

export const findClearTracesButton = (page: Page) =>
  page.locator('button[phx-click="clear-traces"]');

export const findRefreshTracesButton = (page: Page) =>
  page.locator('button[phx-click="refresh-history"]');

export { expect, Page } from '@playwright/test';
