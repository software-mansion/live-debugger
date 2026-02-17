import {
  test,
  expect,
  findTraces,
  findAssignsEntry,
  findSwitchTracingButton,
  findRefreshTracesButton,
  findClearTracesButton,
  Page,
} from './dev-dbg-test';

const findNodeBasicInfo = (page: Page) =>
  page.locator('#node-inspector-basic-info');

const findComponentsTreeButton = (page: Page, name: string) =>
  page.getByRole('button', { name });

test('user can see traces of executed callbacks and updated assigns', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);
  await expect(findAssignsEntry(dbgApp, 'counter', '0')).toBeVisible();
  await expect(traces).toHaveCount(2);

  const incBtn = devApp.getByRole('button', {
    name: 'Increment',
    exact: true,
  });
  await incBtn.click();
  await incBtn.click();

  await expect(findAssignsEntry(dbgApp, 'counter', '2')).toBeVisible();
  await expect(traces).toHaveCount(6);

  await findSwitchTracingButton(dbgApp).click();

  await incBtn.click();
  await incBtn.click();

  await expect(findAssignsEntry(dbgApp, 'counter', '4')).toBeVisible();
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

test('user can change nodes using node tree and see their assigns and callback traces', async ({
  devApp,
  dbgApp,
}) => {
  await findComponentsTreeButton(dbgApp, 'Conditional (5)').click();

  await expect(findNodeBasicInfo(dbgApp)).toContainText('LiveComponent');
  await expect(findNodeBasicInfo(dbgApp)).toContainText(
    'LiveDebuggerDev.LiveComponents.Conditional'
  );

  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();
  await expect(findTraces(dbgApp)).toHaveCount(2);

  await expect(
    findComponentsTreeButton(dbgApp, 'ManyAssigns (15)')
  ).not.toBeVisible();

  await devApp.locator('#conditional-button').click();

  await expect(
    findComponentsTreeButton(dbgApp, 'ManyAssigns (15)')
  ).toBeVisible();

  await expect(findAssignsEntry(dbgApp, 'show_child?', 'true')).toBeVisible();
  await expect(findTraces(dbgApp)).toHaveCount(4);

  await findComponentsTreeButton(dbgApp, 'Conditional (6)').click();
  await findComponentsTreeButton(dbgApp, 'Conditional (5)').click();

  await expect(findAssignsEntry(dbgApp, 'show_child?', 'true')).toBeVisible();
  await expect(findTraces(dbgApp)).toHaveCount(4);

  await devApp.locator('#conditional-button').click();

  await expect(
    findComponentsTreeButton(dbgApp, 'ManyAssigns (15)')
  ).not.toBeVisible();

  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();
  await expect(findTraces(dbgApp)).toHaveCount(6);
});
