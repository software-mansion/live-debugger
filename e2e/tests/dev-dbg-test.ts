/**
 * This file export common helpers for "debugged app <-> debugger" test flow.
 */

import { test as base, Page } from '@playwright/test';

export const prepareDevDebuggerPairTest = (devUrl: string = '/') => {
  return base
    .extend<{ devApp: Page }>({
      devApp: async ({ page }, use) => {
        await page.goto(devUrl);
        await use(page);
      },
    })
    .extend<{ dbgApp: Page }>({
      dbgApp: async ({ devApp }, use) => {
        await devApp.locator('#live-debugger-debug-button').click();
        const dbgAppPromise = devApp.waitForEvent('popup');
        await devApp.getByText('Open in new tab').click();
        const dbgApp = await dbgAppPromise;
        await use(dbgApp);
      },
    });
};

export const findAssignsEntry = (page: Page, key: string, value: string) =>
  page.locator(
    `xpath=//*[@id=\"assigns\"]//*[contains(normalize-space(text()), \"${key}:\")]/../..//*[contains(normalize-space(text()), \"${value}\")]`
  );

export const findTraces = (page: Page) =>
  page.locator('#traces-list-stream details');

export const findSwitchTracingButton = (page: Page) =>
  page.locator('button[phx-click="switch-tracing"]');

export const findClearTracesButton = (page: Page) =>
  page.locator('button[phx-click="clear-traces"]');

export const findRefreshTracesButton = (page: Page) =>
  page.locator('button[phx-click="refresh-history"]');

export const findFiltersButton = (page: Page) =>
  page.locator('button[aria-label="Open filters"]');

export const getDevPid = async (page: Page) => {
  const text = await page.getByText(/Current PID:/).innerText();
  return text.replace('Current PID:', '').trim();
};

export const returnButton = (page: Page) => page.locator('#return-button');
export const findNodeInspectorButton = (page: Page) =>
  page.locator('#node-inspector-navbar-item a');

export const findNodeModuleInfo = (page: Page) =>
  page.locator('#node-inspector-basic-info-current-node-module');

export const findComponentTreeNode = (page: Page, cid: number) =>
  page.locator(`#button-tree-node-${cid}-components-tree`);

export const findSidebarBasicInfo = (page: Page) =>
  page.locator('#node-inspector-basic-info');

export const findGlobalTracesNavbarItem = (page: Page) =>
  page.locator('#global-traces-navbar-item a');

export const setCollapsibleOpenState = async (
  page: Page,
  sectionId: string,
  state: string
) => {
  await page.evaluate(
    ([id, st]) => localStorage.setItem(`lvdbg:collapsible-open-${id}`, st),
    [sectionId, state]
  );
};

export { expect, Page } from '@playwright/test';
