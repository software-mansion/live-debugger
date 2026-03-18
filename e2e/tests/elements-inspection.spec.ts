import { test, expect, Page, BrowserContext } from '@playwright/test';
import { getDevPid, findNodeModuleInfo } from './dev-dbg-test';

const DBG_URL = 'http://localhost:4008';

const switchInspectModeBtn = (page: Page) =>
  page.locator('button[phx-click="switch-inspect-mode"]');

const liveComponent = (page: Page, cid: number) =>
  page.locator(`div[data-phx-component="${cid}"]`);

const inspectModeOverlay = (page: Page) =>
  page.locator('div.live-debugger-inspect-mode');

const inspectTooltipModule = (page: Page) =>
  page.locator('div#live-debugger-tooltip div.live-debugger-tooltip-module');

const inspectTooltipType = (page: Page) =>
  page.locator('div#live-debugger-tooltip span.type-text');

const inspectTooltipValue = (page: Page) =>
  page.locator('div#live-debugger-tooltip .id-info .value');

const sidebarContainer = (page: Page) =>
  page.locator('#components-tree-sidebar-container');

const closeSidebarBtn = (page: Page) =>
  page.locator('button[phx-click="close-sidebar"]');

const selectLiveViewByPid = async (dbgApp: Page, pid: string) => {
  const btn = dbgApp.locator(
    `button[id="${pid}"][phx-click="select-live-view"]`
  );
  await btn.hover();
  await btn.click();
  await expect(findNodeModuleInfo(dbgApp)).toBeVisible();
};

const openDbgForLiveView = async (
  context: BrowserContext,
  pid: string
): Promise<Page> => {
  const dbgApp = await context.newPage();
  await dbgApp.goto(DBG_URL);
  await selectLiveViewByPid(dbgApp, pid);
  return dbgApp;
};

test('user can inspect elements after enabling inspect mode', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();

  const pid = await getDevPid(devApp);
  const dbgApp = await openDbgForLiveView(context, pid);

  await switchInspectModeBtn(dbgApp).click();

  await expect(inspectModeOverlay(devApp)).toBeVisible();

  await liveComponent(devApp, 2).hover();

  await expect(inspectTooltipModule(devApp)).toContainText(
    'LiveDebuggerDev.LiveComponents.Name'
  );
  await expect(inspectTooltipType(devApp)).toContainText('LiveComponent');
  await expect(inspectTooltipValue(devApp)).toContainText('2');

  await liveComponent(devApp, 2).click();

  await expect(inspectModeOverlay(devApp)).not.toBeVisible();
  await expect(findNodeModuleInfo(dbgApp)).toContainText(
    'LiveDebuggerDev.LiveComponents.Name'
  );
});

test('user can disable inspect mode from debugger', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();

  const pid = await getDevPid(devApp);
  const dbgApp = await openDbgForLiveView(context, pid);

  await switchInspectModeBtn(dbgApp).click();
  await expect(inspectModeOverlay(devApp)).toBeVisible();

  await switchInspectModeBtn(dbgApp).click();
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();
});

test('user can disable inspect mode by right clicking', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();

  const pid = await getDevPid(devApp);
  const dbgApp = await openDbgForLiveView(context, pid);

  await switchInspectModeBtn(dbgApp).click();
  await expect(inspectModeOverlay(devApp)).toBeVisible();

  await devApp.locator('body').click({ button: 'right' });
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();
});

test('selecting node redirects all subscribed debugger windows', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  const pid = await getDevPid(devApp);

  const dbgApp1 = await openDbgForLiveView(context, pid);
  await switchInspectModeBtn(dbgApp1).click();

  const dbgApp2 = await openDbgForLiveView(context, pid);
  await switchInspectModeBtn(dbgApp2).click();

  const dbgApp3 = await openDbgForLiveView(context, pid);

  await liveComponent(devApp, 2).click();

  await expect(findNodeModuleInfo(dbgApp1)).toContainText(
    'LiveDebuggerDev.LiveComponents.Name'
  );
  await expect(findNodeModuleInfo(dbgApp2)).toContainText(
    'LiveDebuggerDev.LiveComponents.Name'
  );
  await expect(findNodeModuleInfo(dbgApp3)).toContainText(
    'LiveDebuggerDev.LiveViews.Main'
  );
});

test('inspection works for nested LiveViews in LiveComponents', async ({
  page: devApp,
}) => {
  await devApp.goto('/embedded');
  await expect(inspectModeOverlay(devApp)).not.toBeVisible();

  await devApp.locator('#live-debugger-debug-button').click();
  const dbgAppPromise = devApp.waitForEvent('popup');
  await devApp.getByText('Open in new tab').click();
  const dbgApp = await dbgAppPromise;
  await expect(findNodeModuleInfo(dbgApp)).toBeVisible();

  await switchInspectModeBtn(dbgApp).click();

  await devApp
    .locator('div[data-phx-id*="embedded_wrapper_inner"] span', {
      hasText: 'Simple [LiveView]',
    })
    .click();

  await expect(inspectModeOverlay(devApp)).not.toBeVisible();
  await expect(findNodeModuleInfo(dbgApp)).toContainText(
    'LiveDebuggerDev.LiveViews.Simple'
  );
});

test('sidebar opens automatically on small screens', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  const pid = await getDevPid(devApp);

  const dbgApp = await context.newPage();
  await dbgApp.setViewportSize({ width: 600, height: 1000 });
  await dbgApp.goto(DBG_URL);

  const btn = dbgApp.locator(
    `button[id="${pid}"][phx-click="select-live-view"]`
  );
  await btn.hover();
  await btn.click();
  await expect(switchInspectModeBtn(dbgApp)).toBeVisible();

  await expect(sidebarContainer(dbgApp)).not.toBeVisible();
  await expect(closeSidebarBtn(dbgApp)).not.toBeVisible();

  await switchInspectModeBtn(dbgApp).click();
  await liveComponent(devApp, 2).click();

  await expect(sidebarContainer(dbgApp)).toBeVisible();
  await expect(closeSidebarBtn(dbgApp)).toBeVisible();
});

test('sidebar closes on desktop resize and stays closed', async ({
  page: devApp,
  context,
}) => {
  await devApp.goto('/');
  const pid = await getDevPid(devApp);

  const dbgApp = await context.newPage();
  await dbgApp.setViewportSize({ width: 600, height: 1000 });
  await dbgApp.goto(DBG_URL);

  const btn = dbgApp.locator(
    `button[id="${pid}"][phx-click="select-live-view"]`
  );
  await btn.hover();
  await btn.click();
  await expect(switchInspectModeBtn(dbgApp)).toBeVisible();

  await expect(sidebarContainer(dbgApp)).not.toBeVisible();

  await switchInspectModeBtn(dbgApp).click();
  await liveComponent(devApp, 2).click();

  await expect(sidebarContainer(dbgApp)).toBeVisible();
  await expect(closeSidebarBtn(dbgApp)).toBeVisible();

  await dbgApp.setViewportSize({ width: 1200, height: 1000 });
  await dbgApp.setViewportSize({ width: 600, height: 1000 });

  await expect(sidebarContainer(dbgApp)).not.toBeVisible();
  await expect(closeSidebarBtn(dbgApp)).not.toBeVisible();
});
