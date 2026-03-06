import {
  expect,
  findSwitchTracingButton,
  findRefreshTracesButton,
  findClearTracesButton,
  prepareDevDebuggerPairTest,
  Page,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest();


const globalTracesNavbarItem = (page: Page) => page.locator('#global-traces-navbar-item a');
const globalTracesTitle = (page: Page, text: string) => page.locator('h1', { hasText: text });
const noTracesInfo = (page: Page) => page.locator('#global-traces-stream-empty', { hasText: 'No traces have been recorded yet.' });
const findTraces = (page: Page) => page.locator('#global-traces-stream details');
const traceName = (page: Page, text: string) => page.locator('#global-traces-stream details p.font-medium', { hasText: text });
const traceModule = (page: Page, text: string) => page.locator('#global-traces-stream details div.col-span-3', { hasText: text });
const searchBar = (page: Page) => page.locator('#trace-search-input');
const traceFullscreen = (page: Page) => page.locator('#trace-fullscreen');
const sidebarBasicInfo = (page: Page) => page.locator('#node-inspector-basic-info');
const openFullscreenButton = (page: Page) => page.locator('button[phx-click="open-trace"]');

const traceDiffsCheckbox = (page: Page) => page.locator('#filters-sidebar-form #filters-sidebar-form_trace_diffs');
const componentCheckbox = (page: Page, name: string) => 
  page.locator('#filters-sidebar-form label', { hasText: name }).locator('input[type="checkbox"]');
const applyButton = (page: Page) => page.locator('#filters-sidebar-form button[type="submit"]', { hasText: 'Apply' });
const resetAllButton = (page: Page) => page.locator('#filters-sidebar-form button', { hasText: 'Reset all' });
const filtersSidebar = (page: Page) => page.locator('#filters-sidebar');

test.describe('Global Traces', () => {

  test('user can trace callbacks globally', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await expect(globalTracesTitle(dbgApp, 'Global Callback Traces')).toBeVisible();
    
    await expect(findTraces(dbgApp)).toHaveCount(25);
    
    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await expect(findTraces(dbgApp)).toHaveCount(0);
    await expect(noTracesInfo(dbgApp)).toBeVisible();

    await findSwitchTracingButton(dbgApp).click();
    await devApp.locator('button#send-button').click();
    await findSwitchTracingButton(dbgApp).click();
    
    const traces = findTraces(dbgApp);
    await expect(traces).toHaveCount(3);
    await expect(traceName(dbgApp, 'handle_event/3')).toHaveCount(1);
    await expect(traceName(dbgApp, 'handle_info/2')).toHaveCount(1);
    await expect(traceName(dbgApp, 'render/1')).toHaveCount(1);
    
    await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveViews.Main')).toHaveCount(2);
    await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveComponents.Send (4)')).toHaveCount(1);

    await findClearTracesButton(dbgApp).click();
    await expect(findTraces(dbgApp)).toHaveCount(0);
    await expect(noTracesInfo(dbgApp)).toBeVisible();

    await devApp.locator('button#increment-button').click();
    
    await findRefreshTracesButton(dbgApp).click();
    await expect(findTraces(dbgApp)).toHaveCount(2);
    await expect(traceName(dbgApp, 'handle_event/3')).toHaveCount(1);
    await expect(traceName(dbgApp, 'render/1')).toHaveCount(1);
  });

  test('user can go to specific node from global callbacks', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await devApp.locator('button#send-button').click();

    await dbgApp.getByRole('link', { name: 'LiveDebuggerDev.LiveViews.Main', exact: true }).first().click();

    await expect(sidebarBasicInfo(dbgApp)).toContainText('LiveView');
    await expect(sidebarBasicInfo(dbgApp)).toContainText('LiveDebuggerDev.LiveViews.Main');

    await globalTracesNavbarItem(dbgApp).click();
    await dbgApp.getByRole('link', { name: 'LiveDebuggerDev.LiveComponents.Send (4)', exact: true }).first().click();

    await expect(sidebarBasicInfo(dbgApp)).toContainText('LiveComponent');
    await expect(sidebarBasicInfo(dbgApp)).toContainText('LiveDebuggerDev.LiveComponents.Send');
  });

  test('user can search for callbacks using the searchbar', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await devApp.locator('button#send-button').click();
    await findSwitchTracingButton(dbgApp).click();

    await searchBar(dbgApp).fill(':new_datetime');
    await expect(findTraces(dbgApp)).toHaveCount(1);
    
    await findClearTracesButton(dbgApp).click();
    await devApp.locator('button#increment-button').click();

    await searchBar(dbgApp).fill('deep value');
    await dbgApp.waitForTimeout(250);

    const traces = findTraces(dbgApp);
    await expect(traces).toHaveCount(2);

    const renderTrace = traces.first();
    await renderTrace.locator('summary').click();
    await expect(renderTrace.locator('pre', { hasText: '"deep value"' })).toHaveCount(2);
    
    await openFullscreenButton(dbgApp).first().click();
    await expect(traceFullscreen(dbgApp)).toBeVisible();
    await expect(traceFullscreen(dbgApp).locator('pre', { hasText: '"deep value"' })).toHaveCount(2);
    await dbgApp.locator('#trace-fullscreen-close').click();
  });

  test('incoming traces are filtered by search phrase', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    
    await searchBar(dbgApp).fill(':new_datetime');
    await findSwitchTracingButton(dbgApp).click();

    await devApp.locator('button#send-button').click();
    await expect(findTraces(dbgApp)).toHaveCount(1);
  });

test('user can enable diff tracing and see diff traces', async ({ devApp, dbgApp }) => {
    await dbgApp.setViewportSize({ width: 1920, height: 1080 });
    await globalTracesNavbarItem(dbgApp).click();
    await expect(globalTracesTitle(dbgApp, 'Global Callback Traces')).toBeVisible();
    
    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await expect(findTraces(dbgApp)).toHaveCount(0);
    await expect(noTracesInfo(dbgApp)).toBeVisible();
    await expect(filtersSidebar(dbgApp)).toBeVisible();

    await traceDiffsCheckbox(dbgApp).check();
    await applyButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();

    await devApp.locator('button#increment-button').click();

    await findSwitchTracingButton(dbgApp).click();
    
    const traces = findTraces(dbgApp);
    await expect(traces).toHaveCount(3);
    await expect(traceName(dbgApp, 'handle_event/3')).toBeVisible();
    await expect(traceName(dbgApp, 'render/1')).toBeVisible();
    await expect(traceName(dbgApp, 'Diff sent')).toBeVisible();

    const diffTrace = traces.filter({ hasText: 'Diff sent' }).first();
    await diffTrace.locator('summary').click();
    await expect(diffTrace.locator('pre', { hasText: '"diff"' })).toBeVisible();

    await openFullscreenButton(dbgApp).first().click();
    await expect(traceFullscreen(dbgApp)).toBeVisible();
    await expect(traceFullscreen(dbgApp).locator('pre', { hasText: '"diff"' })).toBeVisible();
    
    await dbgApp.locator('button[phx-click="trace-fullscreen-close"]').click();
    
    await expect(traceFullscreen(dbgApp)).toBeHidden();



    

});
