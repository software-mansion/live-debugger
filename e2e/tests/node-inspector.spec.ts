import { Locator } from '@playwright/test';
import {
  expect,
  findTraces,
  findAssignsEntry,
  findSwitchTracingButton,
  findRefreshTracesButton,
  findClearTracesButton,
  findFiltersButton,
  prepareDevDebuggerPairTest,
  Page,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest();

const findNodeBasicInfo = (page: Page) =>
  page.locator('#node-inspector-basic-info');

const findComponentsTreeButton = (page: Page, name: string) =>
  page.getByRole('button', { name });

const FILTERS_FORM = '#filters-fullscreen-form';

const findCallbackCheckbox = (page: Page, name: string) =>
  page
    .locator(`${FILTERS_FORM} div.flex.items-center`, { hasText: name })
    .locator('input[type="checkbox"]');

const findExecTimeMinInput = (page: Page) =>
  page.locator(`${FILTERS_FORM}_exec_time_min`);

const findExecTimeMaxInput = (page: Page) =>
  page.locator(`${FILTERS_FORM}_exec_time_max`);

const findMinUnitSelect = (page: Page) =>
  page.locator(`${FILTERS_FORM}_min_unit`);

const findMaxUnitSelect = (page: Page) =>
  page.locator(`${FILTERS_FORM}_max_unit`);

const findApplyButton = (page: Page) =>
  page.locator(`${FILTERS_FORM} button[type="submit"]`);

const findResetAllButton = (page: Page) =>
  page.locator(`${FILTERS_FORM} button[phx-click="reset"]`);

const findResetGroupButton = (page: Page, group: string) =>
  page.locator(`button[phx-click="reset-group"][phx-value-group="${group}"]`);

const findResetFiltersButton = (page: Page) =>
  page.locator('button[phx-click="reset-filters"]');

const findSearchBar = (page: Page) => page.locator('#trace-search-input');

const findOpenFullscreenTraceButton = (page: Page) =>
  page.locator('button[phx-click="open-trace"]');

// Tooltip (on devApp)
const findInspectTooltipModuleText = (page: Page) =>
  page.locator('div#live-debugger-tooltip div.live-debugger-tooltip-module');
const findInspectTooltipTypeText = (page: Page) =>
  page.locator('div#live-debugger-tooltip span.type-text');
const findInspectTooltipValueText = (page: Page) =>
  page.locator('div#live-debugger-tooltip .id-info span.value');

// Trace name assertions helper
const assertTraceNames = async (page: Page, expectedNames: string[]) => {
  const traces = findTraces(page);
  await expect(traces).toHaveCount(expectedNames.length);
  for (let i = 0; i < expectedNames.length; i++) {
    await expect(traces.nth(i)).toContainText(expectedNames[i]);
  }
};

// Map entry in trace details (scoped to a trace element)
const findMapEntry = (parent: Locator, key: string, value: string) =>
  parent
    .locator(
      `xpath=.//*[contains(normalize-space(text()), "${key}:")]/../..//*[contains(normalize-space(text()), "${value}")]`
    )
    .first();

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

  await dbgApp.waitForTimeout(405);

  await refreshTracesButton.click();

  await expect(traces).toHaveCount(2);
  await expect(traces.last().locator('span.text-warning-text')).toHaveText(
    /^\s*4\d\d ms\s*$/
  );

  await devApp
    .getByRole('button', { name: 'Very Slow Increment', exact: true })
    .click();

  await dbgApp.waitForTimeout(1110);

  await refreshTracesButton.click();

  await expect(traces).toHaveCount(4);
  await expect(traces.nth(1).locator('span.text-error-text')).toHaveText(
    /^\s*1\.1\d s\s*$/
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

test('Open in editor shows docs link when envs are not set', async ({
  dbgApp,
}) => {
  const openInEditorLink = dbgApp.getByRole('link', {
    name: 'Open in Editor',
  });
  await expect(openInEditorLink).toBeVisible();
  await expect(openInEditorLink).toHaveAttribute(
    'href',
    /open_in_editor\.html/
  );
});

test('user can highlight nodes', async ({ devApp, dbgApp }) => {
  await dbgApp.locator('#button-tree-node-2-components-tree').hover();

  await expect(findInspectTooltipModuleText(devApp)).toContainText(
    'LiveDebuggerDev.LiveComponents.Name'
  );
  await expect(findInspectTooltipTypeText(devApp)).toContainText(
    'LiveComponent'
  );
  await expect(findInspectTooltipValueText(devApp)).toContainText('2');
});

test('user can copy values', async ({ dbgApp }) => {
  await expect(dbgApp.locator('#node-inspector-basic-info')).toContainText(
    'LiveDebuggerDev.LiveViews.Main'
  );

  await dbgApp.evaluate(() => {
    (window as any)._copiedText = null;
    navigator.clipboard.writeText = (text: string) => {
      (window as any)._copiedText = text;
      return Promise.resolve();
    };
    document.execCommand = (cmd: string) => {
      if (cmd === 'copy') {
        const selectedText = window.getSelection()?.toString() ?? '';
        (window as any)._copiedText = selectedText;
        return true;
      }
      return false;
    };
  });

  await dbgApp.locator('button#copy-button-module-name').click();

  const copiedText = await dbgApp.evaluate(() => (window as any)._copiedText);
  expect(copiedText).toBe('LiveDebuggerDev.LiveViews.Main');
});

test('when user navigates in debugged app, it causes dead view mode', async ({
  devApp,
  dbgApp,
}) => {
  await expect(findNodeBasicInfo(dbgApp)).toContainText(
    'LiveDebuggerDev.LiveViews.Main'
  );

  await devApp.getByRole('link', { name: 'Side' }).click();

  await expect(dbgApp.locator('#navbar-connected')).toContainText(
    'Disconnected'
  );

  await dbgApp.getByRole('button', { name: 'Continue' }).click();

  await expect(findNodeBasicInfo(dbgApp)).toContainText(
    'LiveDebuggerDev.LiveViews.Side'
  );
});

test('user can inspect arguments of executed callback', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(2);

  await devApp.locator('button#increment-button').click();
  await devApp.locator('button#send-button').click();

  await expect(traces).toHaveCount(6);

  const render3 = traces.nth(0);
  const handleInfo = traces.nth(1);
  const render2 = traces.nth(2);
  const handleEvent = traces.nth(3);
  const render1 = traces.nth(4);

  await render1.locator('> summary').click();
  await expect(findMapEntry(render1, 'datetime', 'nil')).toBeVisible();
  await expect(findMapEntry(render1, 'counter', '0')).toBeVisible();

  await handleEvent.locator('> summary').click();
  await expect(handleEvent).toContainText('handle_event/3');
  await expect(handleEvent).toContainText('increment');

  await render2.locator('> summary').click();
  await expect(findMapEntry(render2, 'datetime', 'nil')).toBeVisible();
  await expect(findMapEntry(render2, 'counter', '1')).toBeVisible();

  await handleInfo.locator('> summary').click();
  await expect(handleInfo).toContainText('handle_info/2');
  await expect(handleInfo).toContainText(':new_datetime');

  await render3.locator('> summary').click();
  await expect(findMapEntry(render3, 'datetime', '~U[')).toBeVisible();
  await expect(findMapEntry(render3, 'counter', '1')).toBeVisible();
});

test('incoming traces are filtered by search phrase', async ({
  devApp,
  dbgApp,
}) => {
  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(2);

  // Search bar is disabled while tracing is active, stop tracing first
  await findSwitchTracingButton(dbgApp).click();
  await findSearchBar(dbgApp).fill(':new_datetime');
  await expect(traces).toHaveCount(0);

  await findSwitchTracingButton(dbgApp).click();
  await devApp.locator('button#send-button').click();
  await expect(traces).toHaveCount(1);
});

test('user can search for callbacks using the searchbar', async ({
  devApp,
  dbgApp,
}) => {
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();

  await findSwitchTracingButton(dbgApp).click();
  await devApp.locator('button#send-button').click();
  await findSwitchTracingButton(dbgApp).click();

  await findSearchBar(dbgApp).fill(':new_datetime');

  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(1);
  await expect(traces.first()).toContainText(':new_datetime');

  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();
  await devApp.locator('button#increment-button').click();
  await findSwitchTracingButton(dbgApp).click();

  await findSearchBar(dbgApp).fill('deep value');

  await expect(traces).toHaveCount(2);

  const renderTrace = traces.first();
  await renderTrace.locator('> summary').click();
  await expect(
    renderTrace.locator('pre', { hasText: '"deep value"' })
  ).toHaveCount(2);

  await findOpenFullscreenTraceButton(dbgApp).first().click();
  await expect(dbgApp.locator('#trace-fullscreen')).toBeVisible();
  await expect(
    dbgApp
      .locator('#trace-fullscreen')
      .locator('pre', { hasText: '"deep value"' })
  ).toHaveCount(2);
  await dbgApp.locator('#trace-fullscreen-close').click();
  await renderTrace.locator('> summary').click();

  const handleEventTrace = traces.nth(1);
  await handleEventTrace.locator('> summary').click();
  await expect(
    handleEventTrace.locator('pre', { hasText: '"deep value"' })
  ).toHaveCount(1);

  await findOpenFullscreenTraceButton(dbgApp).first().click();
  await expect(dbgApp.locator('#trace-fullscreen')).toBeVisible();
  await expect(
    dbgApp
      .locator('#trace-fullscreen')
      .locator('pre', { hasText: '"deep value"' })
  ).toHaveCount(1);
});

test('user can filter traces by callback name', async ({ devApp, dbgApp }) => {
  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(2);

  await devApp.locator('button#send-button').click();
  await devApp.locator('button#send-button').click();

  await expect(traces).toHaveCount(6);
  await findSwitchTracingButton(dbgApp).click();

  await assertTraceNames(dbgApp, [
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_info/2',
    'render/1',
    'mount/3',
  ]);

  await findFiltersButton(dbgApp).click();
  await expect(dbgApp.locator('dialog#filters-fullscreen')).toBeVisible();
  await findCallbackCheckbox(dbgApp, 'mount/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'render/1').uncheck();
  await findApplyButton(dbgApp).click();

  await assertTraceNames(dbgApp, ['handle_info/2', 'handle_info/2']);

  await devApp.locator('button#increment-button').click();
  await devApp.locator('button#increment-button').click();
  await findRefreshTracesButton(dbgApp).click();

  await assertTraceNames(dbgApp, [
    'handle_event/3',
    'handle_event/3',
    'handle_info/2',
    'handle_info/2',
  ]);

  await findSwitchTracingButton(dbgApp).click();
  await devApp.locator('button#send-button').click();
  await devApp.locator('button#send-button').click();

  await assertTraceNames(dbgApp, [
    'handle_info/2',
    'handle_info/2',
    'handle_event/3',
    'handle_event/3',
    'handle_info/2',
    'handle_info/2',
  ]);

  await findSwitchTracingButton(dbgApp).click();
  await findFiltersButton(dbgApp).click();
  await findResetAllButton(dbgApp).click();
  await findApplyButton(dbgApp).click();

  await assertTraceNames(dbgApp, [
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_event/3',
    'render/1',
    'handle_event/3',
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_info/2',
    'render/1',
    'mount/3',
  ]);

  await findFiltersButton(dbgApp).click();
  await findCallbackCheckbox(dbgApp, 'mount/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_params/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_info/2').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_call/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_cast/2').uncheck();
  await findCallbackCheckbox(dbgApp, 'terminate/2').uncheck();
  await findCallbackCheckbox(dbgApp, 'render/1').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_event/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'handle_async/3').uncheck();
  await findApplyButton(dbgApp).click();

  await expect(traces).toHaveCount(0);
});

test('user can filter traces by execution time', async ({ devApp, dbgApp }) => {
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();

  await devApp.locator('button#slow-increment-button').click();

  const refreshBtn = findRefreshTracesButton(dbgApp);
  await refreshBtn.click();
  await dbgApp.waitForTimeout(405);
  await refreshBtn.click();

  const traces = findTraces(dbgApp);
  await expect(traces).toHaveCount(2);

  await devApp.locator('button#very-slow-increment-button').click();
  await dbgApp.waitForTimeout(1110);
  await refreshBtn.click();

  await expect(traces).toHaveCount(4);

  // Open filters, set exec time min=100ms, max=1s
  await findFiltersButton(dbgApp).click();
  await expect(dbgApp.locator('dialog#filters-fullscreen')).toBeVisible();
  await findMinUnitSelect(dbgApp).selectOption('ms');
  await findExecTimeMinInput(dbgApp).fill('100');
  await findMaxUnitSelect(dbgApp).selectOption('s');
  await findExecTimeMaxInput(dbgApp).fill('1');
  await findApplyButton(dbgApp).click();

  // Should show 1 trace (the slow-increment ~400ms)
  await expect(traces).toHaveCount(1);
  await expect(traces.first().locator('span.text-warning-text')).toHaveText(
    /^\s*4\d\d ms\s*$/
  );

  await findSwitchTracingButton(dbgApp).click();
  await devApp.locator('button#increment-button').click();
  await devApp.locator('button#slow-increment-button').click();

  // Auto-retry waits for slow trace to appear
  await expect(traces).toHaveCount(2);
  for (let i = 0; i < 2; i++) {
    await expect(traces.nth(i).locator('span.text-warning-text')).toHaveText(
      /^\s*4\d\d ms\s*$/
    );
  }
});

test('user can filter traces by names and execution time', async ({
  devApp,
  dbgApp,
}) => {
  await findSwitchTracingButton(dbgApp).click();
  await findClearTracesButton(dbgApp).click();
  await findSwitchTracingButton(dbgApp).click();

  await devApp.locator('button#slow-increment-button').click();
  await devApp.locator('button#increment-button').click();
  await devApp.locator('button#send-button').click();

  // After clear + re-enable, no mount/initial-render. 3 actions = 6 traces:
  // slow-increment: handle_event + render, increment: handle_event + render, send: handle_info + render
  await assertTraceNames(dbgApp, [
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_event/3',
    'render/1',
    'handle_event/3',
  ]);

  await findSwitchTracingButton(dbgApp).click();

  // Open filters, set min exec time 100ms, uncheck mount + render, apply
  await findFiltersButton(dbgApp).click();
  await expect(dbgApp.locator('dialog#filters-fullscreen')).toBeVisible();
  await findMinUnitSelect(dbgApp).selectOption('ms');
  await findExecTimeMinInput(dbgApp).fill('100');
  await findCallbackCheckbox(dbgApp, 'mount/3').uncheck();
  await findCallbackCheckbox(dbgApp, 'render/1').uncheck();
  await findApplyButton(dbgApp).click();

  // Only the slow handle_event (>100ms) passes
  await assertTraceNames(dbgApp, ['handle_event/3']);

  await devApp.locator('button#slow-increment-button').click();
  await devApp.locator('button#send-button').click();
  await dbgApp.waitForTimeout(405);
  await findRefreshTracesButton(dbgApp).click();

  // 2 slow handle_events pass the filter
  await assertTraceNames(dbgApp, ['handle_event/3', 'handle_event/3']);

  await findFiltersButton(dbgApp).click();
  await findResetGroupButton(dbgApp, 'execution_time').click();
  await findApplyButton(dbgApp).click();

  // No mount/render, all exec times: handle_info x2, handle_event x3
  await assertTraceNames(dbgApp, [
    'handle_info/2',
    'handle_event/3',
    'handle_info/2',
    'handle_event/3',
    'handle_event/3',
  ]);

  // Open filters, set exec_time_max=100µs, reset functions group, apply
  await findFiltersButton(dbgApp).click();
  await findExecTimeMaxInput(dbgApp).fill('100');
  await findResetGroupButton(dbgApp, 'functions').click();
  await findApplyButton(dbgApp).click();

  // All callbacks, max 100ms: excludes 2 slow handle_events
  // Total 10 traces - 2 slow = 8: render x5, handle_info x2, handle_event x1
  await assertTraceNames(dbgApp, [
    'render/1',
    'handle_info/2',
    'render/1',
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_event/3',
    'render/1',
  ]);

  await findFiltersButton(dbgApp).click();
  await findCallbackCheckbox(dbgApp, 'handle_info/2').uncheck();
  await findApplyButton(dbgApp).click();

  // Remove handle_info x2: 6 traces
  await assertTraceNames(dbgApp, [
    'render/1',
    'render/1',
    'render/1',
    'render/1',
    'handle_event/3',
    'render/1',
  ]);

  // Click reset-filters button → all 10 traces shown
  await findResetFiltersButton(dbgApp).click();

  await assertTraceNames(dbgApp, [
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_event/3',
    'render/1',
    'handle_info/2',
    'render/1',
    'handle_event/3',
    'render/1',
    'handle_event/3',
  ]);
});
