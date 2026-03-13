import { expect, Page } from '@playwright/test';
import { prepareDevDebuggerPairTest, returnButton } from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const deadSessionsContainer = (page: Page) => page.locator('#dead-sessions');
const toggleDeadLiveViewsBtn = (page: Page) =>
  page.locator('div[phx-click="toggle-dead-liveviews"]');

const deadSessionItems = (page: Page) =>
  page.locator('#dead-sessions button[phx-click="select-live-view"]');
const navbarConnected = (page: Page) => page.locator('#navbar-connected');

test('dead LiveViews are available to debug', async ({ devApp, dbgApp }) => {
  await returnButton(dbgApp).click();

  if (await deadSessionsContainer(dbgApp).isVisible()) {
    await toggleDeadLiveViewsBtn(dbgApp).click();
  }
  await expect(deadSessionsContainer(dbgApp)).not.toBeVisible();

  await toggleDeadLiveViewsBtn(dbgApp).click();

  await expect(deadSessionsContainer(dbgApp)).toContainText(
    'No dead LiveViews'
  );

  await devApp.goto('/side');
  await devApp.goto('/');

  await expect(deadSessionItems(dbgApp)).toHaveCount(2);

  await deadSessionItems(dbgApp).first().click();

  await expect(navbarConnected(dbgApp)).toContainText('Disconnected');
});
