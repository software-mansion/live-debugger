import {
  test,
  expect,
  findTraces,
  findSwitchTracingButton,
  findRefreshTracesButton,
  findClearTracesButton,
} from './dev-dbg-test';

const globalTracesNavbarItem = (page) => page.locator('#global-traces-navbar-item a');
const globalTracesTitle = (page) => page.getByRole('heading', { name: 'Global Callback Traces' });
const noTracesInfo = (page) => page.locator('text=No traces found');
const traceName = (page, text) => page.locator('#global-traces-stream details p.font-medium', { hasText: text });
const traceModule = (page, text) => page.locator('#global-traces-stream details div.col-span-3', { hasText: text });
const openFullscreenButton = (page) => page.locator('button[phx-click="open-trace"]');
const traceFullscreen = (page) => page.locator('#trace-fullscreen');
const closeFullscreenButton = (page) => page.getByRole('button', { name: /close/i }).or(page.locator('button[phx-click="close-trace-fullscreen"]'));

test.describe('Global Traces', () => {

  test('user can trace callbacks globally', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await expect(globalTracesTitle(dbgApp)).toBeVisible();
    
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
    await devApp.locator('button#increment-button').click();
    
    await findRefreshTracesButton(dbgApp).click();
    await expect(traces).toHaveCount(2);
  });

  test('user can search for callbacks using the searchbar', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();

    await devApp.locator('button#send-button').click();
    await findSwitchTracingButton(dbgApp).click();

    await searchBar(dbgApp).fill(':new_datetime');
    await dbgApp.waitForTimeout(300); 
    await expect(findTraces(dbgApp)).toHaveCount(1);
    
    await findClearTracesButton(dbgApp).click();
    await searchBar(dbgApp).fill('');

    await devApp.locator('button#increment-button').click();
    await findRefreshTracesButton(dbgApp).click();
    await searchBar(dbgApp).fill('deep value');
    await dbgApp.waitForTimeout(300);

    const traces = findTraces(dbgApp);
    await expect(traces).toHaveCount(2);

    const renderTrace = traces.first();
    await renderTrace.locator('summary').click();
    await expect(renderTrace.locator('pre', { hasText: '"deep value"' })).toHaveCount(2);
    
    await openFullscreenButton(dbgApp).first().click();
    await expect(traceFullscreen(dbgApp)).toBeVisible();
    await expect(traceFullscreen(dbgApp).locator('pre', { hasText: '"deep value"' })).toHaveCount(2);
    await closeFullscreenButton(dbgApp).click();
  });

  test('user can enable diff tracing and see diff traces', async ({ devApp, dbgApp }) => {
    await dbgApp.setViewportSize({ width: 1920, height: 1080 });
    
    await globalTracesNavbarItem(dbgApp).click();
    await findClearTracesButton(dbgApp).click();

    const diffCheckbox = dbgApp.locator('#filters-sidebar-form_trace_diffs');
    const applyBtn = dbgApp.locator('#filters-sidebar-form button[type="submit"]', { hasText: 'Apply' });
    
    await diffCheckbox.check();
    await applyBtn.click();

    await findSwitchTracingButton(dbgApp).click();
    await devApp.locator('button#increment-button').click();
    await findSwitchTracingButton(dbgApp).click();

    await expect(findTraces(dbgApp)).toHaveCount(3);
    await expect(traceName(dbgApp, 'Diff sent')).toBeVisible();

    const diffTrace = findTraces(dbgApp).locator('text=Diff sent');
    await expect(dbgApp.locator('pre', { hasText: '"diff"' }).first()).toBeVisible();
  });

  test('user can go to specific node from global callbacks', async ({ devApp, dbgApp }) => {
    await globalTracesNavbarItem(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();
    await devApp.locator('button#send-button').click();

    await dbgApp.locator('a', { hasText: 'LiveDebuggerDev.LiveViews.Main' }).first().click();

    await expect(dbgApp.locator('text=LiveView')).toBeVisible();
    await expect(dbgApp.locator('text=LiveDebuggerDev.LiveViews.Main')).toBeVisible();
  });
});

  // const componentCheckbox = (page, name) => page.locator('#filters-sidebar-form label', { hasText: name }).locator('input[type="checkbox"]');
  // const applyButton = (page) => page.locator('#filters-sidebar-form button[type="submit"]', { hasText: 'Apply' });
  // const resetAllButton = (page) => page.locator('#filters-sidebar-form button', { hasText: 'Reset all' });

//   test('user can filter traces by specific components in the tree', async ({ devApp, dbgApp }) => {
//     await dbgApp.setViewportSize({ width: 1920, height: 1080 });
//     await globalTracesNavbarItem(dbgApp).click();
//     await findClearTracesButton(dbgApp).click();
//     await findSwitchTracingButton(dbgApp).click();

//     await devApp.locator('button#send-button').click();
//     await findSwitchTracingButton(dbgApp).click();

//     const traces = findTraces(dbgApp);

//     await componentCheckbox(dbgApp, 'LiveComponents.Send').uncheck();
//     await applyButton(dbgApp).click();

//     await expect(traces).toHaveCount(2);
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveComponents.Send')).toHaveCount(0);
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveViews.Main')).toHaveCount(2);

//     await componentCheckbox(dbgApp, 'LiveViews.Main').uncheck();
//     await applyButton(dbgApp).click();

//     await expect(traces).toHaveCount(0);
//     await expect(noTracesInfo(dbgApp)).toBeVisible();

//     await resetAllButton(dbgApp).click();
//     await expect(traces).toHaveCount(3);
//     await expect(componentCheckbox(dbgApp, 'LiveViews.Main')).toBeChecked();
//     await expect(componentCheckbox(dbgApp, 'LiveComponents.Send')).toBeChecked();
//   });

//   test('new incoming traces are filtered by component selection', async ({ devApp, dbgApp }) => {
//     await globalTracesNavbarItem(dbgApp).click();
//     await findClearTracesButton(dbgApp).click();

//     await componentCheckbox(dbgApp, 'LiveComponents.Send').uncheck();
//     await applyButton(dbgApp).click();

//     await findSwitchTracingButton(dbgApp).click();

//     await devApp.locator('button#send-button').click();

//     const traces = findTraces(dbgApp);
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveComponents.Send')).toHaveCount(0);
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveViews.Main')).toBeVisible();
//   });

// test('initial state: all components are checked by default and traces are visible', async ({ devApp, dbgApp }) => {
//     await globalTracesNavbarItem(dbgApp).click();
    
//     const mainViewCheckbox = componentCheckbox(dbgApp, 'LiveViews.Main');
//     const sendCompCheckbox = componentCheckbox(dbgApp, 'LiveComponents.Send');
    
//     await expect(mainViewCheckbox).toBeChecked();
//     await expect(sendCompCheckbox).toBeChecked();

//     await findClearTracesButton(dbgApp).click();
//     await findSwitchTracingButton(dbgApp).click();
    
//     await devApp.locator('button#send-button').click();
    
//     const traces = findTraces(dbgApp);
//     await expect(traces).toHaveCount(3);
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveViews.Main')).toBeVisible();
//     await expect(traceModule(dbgApp, 'LiveDebuggerDev.LiveComponents.Send')).toBeVisible();
//   });

//   test('async tree loading: tree appears after initial load and is interactive', async ({ dbgApp }) => {
//     await globalTracesNavbarItem(dbgApp).click();

//     const loader = dbgApp.locator('text=Loading components tree...');
    
//     if (await loader.isVisible()) {
//       await expect(loader).toBeHidden();
//     }

//     const treeContainer = dbgApp.locator('#filters-component-tree-collapse');
//     await expect(treeContainer).toBeVisible();
    
//     const checkbox = componentCheckbox(dbgApp, 'LiveViews.Main');
//     await checkbox.uncheck();
//     await expect(checkbox).not.toBeChecked();
    
//     const applyBtn = applyButton(dbgApp);
//   });
