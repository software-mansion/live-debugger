import {
  expect,
  findClearTracesButton,
  prepareDevDebuggerPairTest,
  Page,
  findSwitchTracingButton,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest();

const termEntry = (
  page: Page,
  containerId: string,
  key: string,
  value: string
) =>
  page.locator(
    `xpath=//*[@id="${containerId}"]//*[contains(normalize-space(text()), "${key}:")]/../..//*[contains(normalize-space(text()), "${value}")]`
  );

const showButton = async (page: Page, selector: string) => {
  await page.evaluate((sel) => {
    const el = document.querySelector(sel);
    if (el) (el as HTMLElement).style.display = 'block';
  }, selector);
};

const clickPinButton = async (page: Page, assignKey: string) => {
  const selector = `#all-assigns button[phx-click="pin-assign"][phx-value-key="${assignKey}"]`;
  await showButton(page, selector);
  await page.locator(selector).click({ force: true });
};

const clickUnpinButton = async (page: Page, assignKey: string) => {
  const selector = `#pinned-assigns button[phx-click="unpin-assign"][phx-value-key="${assignKey}"]`;
  await showButton(page, selector);
  await page.locator(selector).click({ force: true });
};

test('user can search assigns using the searchbar', async ({ dbgApp }) => {
  await expect(termEntry(dbgApp, 'all-assigns', 'counter', '0')).toBeVisible();

  await expect(
    dbgApp.locator('#all-assigns pre').filter({ hasText: '"deep value"' })
  ).not.toBeVisible();

  await dbgApp.locator('#assigns-search-input').fill('deep value');
  await expect(
    dbgApp.locator('#all-assigns pre').filter({ hasText: '"deep value"' })
  ).toBeVisible();

  await dbgApp.reload();

  await dbgApp.locator('button[aria-label="Icon expand"]').click();

  await expect(
    dbgApp
      .locator('#all-assigns-fullscreen pre')
      .filter({ hasText: '"deep value"' })
  ).not.toBeVisible();

  await dbgApp.locator('#assigns-search-input-fullscreen').fill('deep value');
  await expect(
    dbgApp
      .locator('#all-assigns-fullscreen pre')
      .filter({ hasText: '"deep value"' })
  ).toBeVisible();
});

test('user can pin and unpin specific assigns', async ({ devApp, dbgApp }) => {
  await expect(dbgApp.locator('#pinned-assigns')).toContainText(
    'No pinned assigns'
  );

  await clickPinButton(dbgApp, 'counter');
  await expect(
    termEntry(dbgApp, 'pinned-assigns', 'counter', '0')
  ).toBeVisible();

  await devApp.locator('#increment-button').click();
  await devApp.locator('#increment-button').click();
  await devApp.locator('#send-button').click();

  await expect(termEntry(dbgApp, 'all-assigns', 'counter', '2')).toBeVisible();
  await expect(
    termEntry(dbgApp, 'pinned-assigns', 'counter', '2')
  ).toBeVisible();

  await clickUnpinButton(dbgApp, 'counter');
  await expect(dbgApp.locator('#pinned-assigns')).toContainText(
    'No pinned assigns'
  );
});

test('user can see temporary assigns', async ({ devApp, dbgApp }) => {
  await expect(
    termEntry(dbgApp, 'temporary-assigns', 'message', 'nil')
  ).toBeVisible();

  await devApp.locator('#append-message').click();
  await expect(
    termEntry(dbgApp, 'temporary-assigns', 'message', '%{...}')
  ).toBeVisible();

  await devApp.locator('#increment-button').click();
  await expect(
    termEntry(dbgApp, 'temporary-assigns', 'message', '%{...}')
  ).toBeVisible();

  await devApp.goto('/nested');
  await dbgApp.getByRole('button', { name: 'Continue' }).click();

  await expect(dbgApp.locator('#temporary-assigns')).toContainText(
    'No temporary assigns'
  );
});

test('user can go through assigns change history', async ({
  devApp,
  dbgApp,
}) => {
  await devApp.locator('#increment-button').click();
  await devApp.locator('#increment-button').click();
  await devApp.locator('#send-button').click();

  await dbgApp
    .locator('#all-assigns button[phx-click="open-assigns-history"]')
    .click();

  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'datetime', 'nil')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'datetime', '~U[')
  ).toBeVisible();

  await dbgApp.locator('button[phx-click="go-back"]').click();
  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'counter', '1')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'datetime', 'nil')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'datetime', 'nil')
  ).toBeVisible();

  await dbgApp.locator('button[phx-click="go-forward"]').click();
  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'datetime', 'nil')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'datetime', '~U[')
  ).toBeVisible();

  await dbgApp.locator('button[phx-click="go-back-end"]').click();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '0')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'datetime', 'nil')
  ).toBeVisible();

  await dbgApp.locator('button[phx-click="go-forward-end"]').click();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '2')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'datetime', '~U[')
  ).toBeVisible();

  await devApp.locator('#increment-button').click();
  await devApp.locator('#increment-button').click();

  await expect(
    termEntry(dbgApp, 'history-old-assigns', 'counter', '3')
  ).toBeVisible();
  await expect(
    termEntry(dbgApp, 'history-new-assigns', 'counter', '4')
  ).toBeVisible();

  await dbgApp.locator('#assigns-history-close').click();
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await dbgApp
    .locator('#all-assigns button[phx-click="open-assigns-history"]')
    .click();
  await expect(dbgApp.locator('#assigns-history')).toContainText(
    'No history records'
  );
});
