import {
  test,
  expect,
  findTraces,
  assigns_entry,
  findSwitchTracingButton,
  findRefreshTracesButton,
  findClearTracesButton,
} from './dev-dbg-test';

test('user can see traces of executed callbacks and updated assigns', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);
  await expect(assigns_entry(dbgApp, 'counter', '0')).toBeVisible();
  await expect(traces).toHaveCount(2);

  const incBtn = devApp.getByRole('button', {
    name: 'Increment',
    exact: true,
  });
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

test('Open in editor is disabled when envs are not set', async ({ dbgApp }) => {
  console.log(process.env);
  const openButton = dbgApp.getByRole('button', { name: 'Open in editor' });

  await expect(openButton).toBeDisabled();
});
