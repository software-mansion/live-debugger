import { test, expect } from '@playwright/test';

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

  await devApp2.waitForTimeout(200);

  const devPidString2 =
    (await devApp2.locator('#current-pid').textContent()) ?? '';

  await expect(dbgApp.getByText(devPidString2)).toBeVisible();
});
