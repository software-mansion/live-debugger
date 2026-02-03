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

function assigns_entry(page: Page, key: string, value: string) {
  return page.locator(
    `xpath=//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"${key}:\")]/../..//*[contains(normalize-space(text()), \"${value}\")]`
  );
}

function findTraces(page: Page) {
  return page.locator('#traces-list-stream details');
}

const findSwitchTracingButton = (page: Page) =>
  page.locator('button[phx-click="switch-tracing"]');

const findClearTracesButton = (page: Page) =>
  page.locator('button[phx-click="clear-traces"]');

const findRefreshTracesButton = (page: Page) =>
  page.locator('button[phx-click="refresh-history"]');

test('user can see traces of executed callbacks and updated assigns', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);
  await expect(assigns_entry(dbgApp, 'counter', '0')).toBeVisible();
  await expect(traces).toHaveCount(2);

  const incBtn = devApp.getByRole('button', { name: 'Increment', exact: true });
  await incBtn.click();
  await incBtn.click();

  await expect(assigns_entry(dbgApp, 'counter', '2')).toBeVisible();
  await expect(traces).toHaveCount(6);

  await findSwitchTracingButton(dbgApp).click();

  await incBtn.click();
  await incBtn.click();

  await expect(assigns_entry(dbgApp, 'counter', '4')).toBeVisible();
  await expect(traces).toHaveCount(6);

  await findRefreshTracesButton(dbgApp).click();

  await expect(traces).toHaveCount(10);

  await findClearTracesButton(dbgApp).click();

  await expect(traces).toHaveCount(0);
});

test('callback traces have proper execution times displayed', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);

  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();

  await devApp
    .getByRole('button', { name: 'Slow Increment', exact: true })
    .click();

  const refreshTracesButton = findRefreshTracesButton(dbgApp);
  await refreshTracesButton.click();

  await expect(traces).toHaveCount(0);

  await dbgApp.waitForTimeout(405);

  await refreshTracesButton.click();

  await expect(traces).toHaveCount(2);
  await expect(traces.last().locator('span.text-warning-text')).toHaveText(
    /40\d ms/
  );

  await devApp
    .getByRole('button', { name: 'Very Slow Increment', exact: true })
    .click();

  await dbgApp.waitForTimeout(1110);

  await refreshTracesButton.click();

  await expect(traces).toHaveCount(4);
  await expect(traces.nth(1).locator('span.text-error-text')).toHaveText(
    /1\.10 s/
  );
});

test('settings button exists and redirects works as expected', async ({
  dbgApp,
}) => {
  await expect(dbgApp.locator('#traces')).toContainText('Callback traces');
  await dbgApp.getByRole('link', { name: 'Icon settings' }).click();
  await expect(dbgApp.getByRole('heading')).toHaveText('Settings');
  await dbgApp.getByRole('link', { name: 'Icon arrow left' }).click();
  await expect(dbgApp.locator('#traces')).toContainText('Callback traces');
});

test('return button redirects to active live views dashboard', async ({
  dbgApp,
}) => {
  await expect(dbgApp.locator('#traces')).toContainText('Callback traces');
  await dbgApp.getByRole('link', { name: 'Icon arrow left' }).click();
  await expect(
    dbgApp.getByRole('heading', { name: 'Active LiveViews' })
  ).toBeVisible();
});
