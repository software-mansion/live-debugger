import { test as baseTest, expect, Page } from '@playwright/test';
import {
  prepareDevDebuggerPairTest,
  findComponentTreeNode,
  findNodeModuleInfo,
  setCollapsibleOpenState,
} from './dev-dbg-test';

const testStream = prepareDevDebuggerPairTest('/stream');
const testRoot = prepareDevDebuggerPairTest('/');

const createItemBtn = (page: Page) => page.locator('button#create-item');
const createAnotherItemBtn = (page: Page) =>
  page.locator('button#create-another-item');
const resetItemsBtn = (page: Page) => page.locator('button#reset-items');
const deleteItemBtn = (page: Page) => page.locator('button#delete-item');
const addNewStreamBtn = (page: Page) => page.locator('button#add-new-stream');

const streamsDisplay = (page: Page) =>
  page.locator('#streams-display-container');
const streamsCollapsible = (page: Page) =>
  page.locator('summary#streams-section-container-summary');

const itemsDisplay = (page: Page) => page.locator('#items-display');
const anotherItemsDisplay = (page: Page) =>
  page.locator('#another_items-display');
const newItemsDisplay = (page: Page) => page.locator('#new_items-display');
const componentItemsDisplay = (page: Page) =>
  page.locator('#component_items-display');

const itemsStreamDetails = (page: Page) =>
  page.locator('#items-stream > details');
const anotherItemsStreamDetails = (page: Page) =>
  page.locator('#another_items-stream > details');
const componentItemsStreamDetails = (page: Page) =>
  page.locator('#component_items-stream > details');

testStream.describe('LiveDebugger Streams', () => {
  testStream.beforeEach(async ({ dbgApp }) => {
    await setCollapsibleOpenState(dbgApp, 'streams-section-container', 'true');
    await dbgApp.reload();
  });

  testStream(
    'User can see modifications of the stream updates',
    async ({ devApp, dbgApp }) => {
      await expect(itemsDisplay(dbgApp)).toBeVisible();
      await itemsDisplay(dbgApp).click();

      await expect(anotherItemsDisplay(dbgApp)).toBeVisible();
      await anotherItemsDisplay(dbgApp).click();

      await createItemBtn(devApp).click();
      await createItemBtn(devApp).click();
      await createAnotherItemBtn(devApp).click();

      await expect(anotherItemsStreamDetails(dbgApp)).toHaveCount(1);
      await expect(itemsStreamDetails(dbgApp)).toHaveCount(2);

      await resetItemsBtn(devApp).click();

      await expect(itemsStreamDetails(dbgApp)).toHaveCount(0);

      await createItemBtn(devApp).click();
      await createItemBtn(devApp).click();
      await createItemBtn(devApp).click();
      await createItemBtn(devApp).click();
      await deleteItemBtn(devApp).click();

      await expect(itemsStreamDetails(dbgApp)).toHaveCount(3);

      await addNewStreamBtn(devApp).click();

      await expect(newItemsDisplay(dbgApp)).toBeVisible();
    }
  );

  testStream(
    'User can see streams in LiveView and LiveComponents',
    async ({ devApp, dbgApp }) => {
      await createItemBtn(devApp).click();

      await expect(itemsDisplay(dbgApp)).toBeVisible();
      await itemsDisplay(dbgApp).click();

      await expect(anotherItemsDisplay(dbgApp)).toBeVisible();
      await anotherItemsDisplay(dbgApp).click();

      await findComponentTreeNode(dbgApp, 1).click();

      await expect(findNodeModuleInfo(dbgApp)).toContainText('StreamComponent');
      await expect(componentItemsDisplay(dbgApp)).toBeVisible();

      await componentItemsDisplay(dbgApp).click();

      await expect(componentItemsStreamDetails(dbgApp)).toHaveCount(3);
    }
  );

  testStream('collapsible state stays after navigation', async ({ dbgApp }) => {
    await expect(streamsDisplay(dbgApp)).toBeVisible();
    await setCollapsibleOpenState(dbgApp, 'streams-section-container', 'false');
    await dbgApp.reload();
    await expect(streamsDisplay(dbgApp)).not.toBeVisible();

    await setCollapsibleOpenState(dbgApp, 'streams-section-container', 'true');
    await dbgApp.reload();
    await expect(streamsDisplay(dbgApp)).toBeVisible();
  });
});

baseTest(
  'User can see modifications to the stream that occurred before it was rendered in debugger.',
  async ({ page, context }) => {
    const devApp = page;
    await devApp.goto('/stream');

    await createItemBtn(devApp).click();
    await createItemBtn(devApp).click();
    await resetItemsBtn(devApp).click();
    await createItemBtn(devApp).click();
    await createItemBtn(devApp).click();
    await deleteItemBtn(devApp).click();
    await createAnotherItemBtn(devApp).click();
    await createAnotherItemBtn(devApp).click();
    await addNewStreamBtn(devApp).click();

    await devApp.locator('#live-debugger-debug-button').click();
    const dbgAppPromise = context.waitForEvent('page');
    await devApp.getByText('Open in new tab').click();
    const dbgApp = await dbgAppPromise;

    await setCollapsibleOpenState(dbgApp, 'streams-section-container', 'true');
    await dbgApp.reload();

    await expect(itemsDisplay(dbgApp)).toBeVisible();
    await itemsDisplay(dbgApp).click();

    await expect(anotherItemsDisplay(dbgApp)).toBeVisible();
    await anotherItemsDisplay(dbgApp).click();

    await expect(newItemsDisplay(dbgApp)).toBeVisible();

    await expect(anotherItemsStreamDetails(dbgApp)).toHaveCount(2);
    await expect(itemsStreamDetails(dbgApp)).toHaveCount(1);
  }
);

testRoot.describe('LiveDebugger Default Root', () => {
  testRoot(
    'User does not see streams section if there are no streams',
    async ({ dbgApp }) => {
      await expect(streamsDisplay(dbgApp)).not.toBeVisible();
    }
  );
});
