import { test, expect, Page } from '@playwright/test';

const findInspectTooltipModuleText = (page: Page) =>
  page.locator('div#live-debugger-tooltip div.live-debugger-tooltip-module');
const findInspectTooltipTypeText = (page: Page) =>
  page.locator('div#live-debugger-tooltip span.type-text');

test('user can see active live views and their highlights which are refreshed automatically', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');

  const dbgApp = await context.newPage();
  await dbgApp.goto('http://localhost:4008');

  await expect(
    dbgApp.getByRole('heading', { name: 'Active LiveViews' })
  ).toBeVisible();

  const devPidString1 =
    (await devApp.locator('#current-pid').textContent()) ?? '';

  await expect(dbgApp.getByText(devPidString1)).toBeVisible();

  const devApp2 = await context.newPage();
  devApp2.goto('/');

  const devPidString2 =
    (await devApp2.locator('#current-pid').textContent()) ?? '';

  await expect(dbgApp.getByText(devPidString2)).toBeVisible();

  await dbgApp.getByText(devPidString1).hover();
  await expect(findInspectTooltipModuleText(devApp)).toContainText(
    'LiveDebuggerDev.LiveViews.Main'
  );
  await expect(findInspectTooltipTypeText(devApp)).toContainText('LiveView');

  await expect(findInspectTooltipModuleText(devApp2)).not.toBeVisible();
  await expect(findInspectTooltipTypeText(devApp2)).not.toBeVisible();

  await dbgApp.getByText(devPidString2).hover();
  await expect(findInspectTooltipModuleText(devApp2)).toContainText(
    'LiveDebuggerDev.LiveViews.Main'
  );
  await expect(findInspectTooltipTypeText(devApp2)).toContainText('LiveView');

  await expect(findInspectTooltipModuleText(devApp)).not.toBeVisible();
  await expect(findInspectTooltipTypeText(devApp)).not.toBeVisible();
});

test('settings button exists and redirects works as expected', async ({
  page: dbgApp,
}) => {
  await dbgApp.goto('http://localhost:4008');

  await expect(
    dbgApp.getByRole('heading', { name: 'Active LiveViews' })
  ).toBeVisible();

  await dbgApp.getByRole('link', { name: 'Icon settings' }).click();

  await expect(dbgApp.getByRole('heading')).toHaveText('Settings');

  await dbgApp.getByRole('link', { name: 'Icon arrow left' }).click();

  await expect(
    dbgApp.getByRole('heading', { name: 'Active LiveViews' })
  ).toBeVisible();
});
