import { test, expect, Page } from '@playwright/test';

function assigns_entry(page: Page, key: string, value: string) {
  return page.locator(`xpath=//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"${key}:\")]/../..//*[contains(normalize-space(text()), \"${value}\")]`)
}

test('user can see traces of executed callbacks and updated assigns', async ({ context }) => {
  const devApp = await context.newPage();

  await devApp.goto('http://localhost:4005/');

  await devApp.locator('#live-debugger-debug-button').click();
  const dbgPromise = devApp.waitForEvent('popup');
  await devApp.getByText('Open in new tab').click();
  const dbg = await dbgPromise;

  await expect(assigns_entry(dbg, 'counter', '0')).toBeVisible();
  await expect(dbg.locator('#traces-list-stream details')).toHaveCount(2);

  const incBtn = devApp.getByRole('button', { name: 'Increment', exact: true });
  await incBtn.click();
  await incBtn.click();

  await expect(assigns_entry(dbg, 'counter', '2')).toBeVisible();
  await expect(dbg.locator('#traces-list-stream details')).toHaveCount(6);
});
