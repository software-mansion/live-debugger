import { expect, Page } from '@playwright/test';
import {
  findSwitchTracingButton,
  findClearTracesButton,
  findSidebarBasicInfo,
  findGlobalTracesNavbarItem,
  findNodeInspectorButton,
  prepareDevDebuggerPairTest,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const navbarConnected = (page: Page) => page.locator('#navbar-connected');
const componentsTree = (page: Page) => page.locator('#components-tree');
const crashComponentBtn = (page: Page) =>
  page.getByRole('button', { name: 'Crash (3)' });
const globalTracesDetails = (page: Page) =>
  page.locator('#global-traces-stream > details');
const globalTracesWithError = (page: Page) =>
  page.locator('#global-traces-stream > details.border-error-border');

const devCrashBtn = (page: Page) => page.locator('button[phx-click="crash"]');

test.describe('LiveDebugger Dead View Mode', () => {
  test('dead view mode with navigation', async ({ devApp, dbgApp }) => {
    await expect(navbarConnected(dbgApp)).toContainText('Monitored PID');

    await devApp.reload();
    await expect(navbarConnected(dbgApp)).toContainText('Disconnected');

    await expect(componentsTree(dbgApp)).toBeVisible();
    await crashComponentBtn(dbgApp).click();

    await expect(findSidebarBasicInfo(dbgApp)).toContainText(
      'LiveDebuggerDev.LiveComponents.Crash'
    );

    await findGlobalTracesNavbarItem(dbgApp).click();
    await expect(globalTracesDetails(dbgApp)).toHaveCount(25);
  });

  test('traces ended with exception are visible in dead view mode', async ({
    devApp,
    dbgApp,
  }) => {
    await findGlobalTracesNavbarItem(dbgApp).click();

    await findSwitchTracingButton(dbgApp).click();
    await findClearTracesButton(dbgApp).click();
    await findSwitchTracingButton(dbgApp).click();

    await devCrashBtn(devApp).click();

    await expect(globalTracesWithError(dbgApp)).toHaveCount(1);
  });
});
