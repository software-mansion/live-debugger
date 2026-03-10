import { expect, Page } from '@playwright/test';
import {
  findSwitchTracingButton,
  prepareDevDebuggerPairTest,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const navbarConnected = (page: Page) => page.locator('#navbar-connected');
const componentsTree = (page: Page) => page.locator('#components-tree');
const crashComponentBtn = (page: Page) =>
  page.getByRole('button', { name: 'Crash (3)' });
const sidebarBasicInfo = (page: Page) =>
  page.locator('#node-inspector-basic-info');

const globalCallbackTracesBtn = (page: Page) =>
  page.locator('#global-traces-navbar-item a');
const nodeInspectorBtn = (page: Page) =>
  page.locator('#node-inspector-navbar-item a');

const globalTracesDetails = (page: Page) =>
  page.locator('#global-traces-stream > details');
const globalTracesWithError = (page: Page) =>
  page.locator('#global-traces-stream > details.border-error-border');

const devCrashBtn = (page: Page) => page.locator('button[phx-click="crash"]');

const clearTracesBtn = (page: Page) =>
  page.locator('button[phx-click="clear-traces"]');
const toggleTracingBtn = (page: Page) =>
  page.locator('button[phx-click="switch-tracing"]');

test.describe('LiveDebugger Dead View Mode', () => {
  test('dead view mode with navigation', async ({ devApp, dbgApp }) => {
    await expect(navbarConnected(dbgApp)).toContainText('Monitored PID');

    await devApp.evaluate(() => window.location.reload());

    await expect(navbarConnected(dbgApp)).toContainText('Disconnected');

    await expect(componentsTree(dbgApp)).toBeVisible();
    await crashComponentBtn(dbgApp).click();

    await expect(sidebarBasicInfo(dbgApp)).toContainText(
      'LiveDebuggerDev.LiveComponents.Crash'
    );

    await globalCallbackTracesBtn(dbgApp).click();
    await expect(globalTracesDetails(dbgApp)).toHaveCount(25);

    await nodeInspectorBtn(dbgApp).click();
  });

  test('traces ended with exception are visible in dead view mode', async ({
    devApp,
    dbgApp,
  }) => {
    await globalCallbackTracesBtn(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await clearTracesBtn(dbgApp).click();
    await toggleTracingBtn(dbgApp).click();

    await devCrashBtn(devApp).click();

    await expect(globalTracesWithError(dbgApp)).toHaveCount(1);
  });
});
