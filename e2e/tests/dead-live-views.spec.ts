import { expect, Page } from '@playwright/test';
import {
  prepareDevDebuggerPairTest,
  returnButton,
  getDevPid,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const deadSessionsContainer = (page: Page) => page.locator('#dead-sessions');
const toggleDeadLiveViewsBtn = (page: Page) =>
  page.locator('div[phx-click="toggle-dead-liveviews"]');
const navbarConnected = (page: Page) => page.locator('#navbar-connected');

test('dead LiveViews are available to debug', async ({ devApp, dbgApp }) => {
  const pid = await getDevPid(devApp);

  await returnButton(dbgApp).click();

  await expect(
    dbgApp.getByRole('heading', { name: 'Active LiveViews' })
  ).toBeVisible();

  if (await deadSessionsContainer(dbgApp).isVisible()) {
    await toggleDeadLiveViewsBtn(dbgApp).click();
  }
  await expect(deadSessionsContainer(dbgApp)).not.toBeVisible();

  await toggleDeadLiveViewsBtn(dbgApp).click();
  await expect(deadSessionsContainer(dbgApp)).toBeVisible();

  await devApp.goto('/side');
  await devApp.goto('/');

  const deadPidBtn = dbgApp.locator(
    `#dead-sessions button[id="${pid}"][phx-click="select-live-view"]`
  );
  await expect(deadPidBtn).toBeVisible();
  await deadPidBtn.hover();
  await deadPidBtn.click();

  await expect(navbarConnected(dbgApp)).toBeVisible();
  await expect(navbarConnected(dbgApp)).toContainText('Disconnected');
});
