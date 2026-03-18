import { expect, Page } from '@playwright/test';
import {
  prepareDevDebuggerPairTest,
  findAssignsEntry,
  findSidebarBasicInfo,
  findComponentTreeNode,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const sendEventButton = (page: Page) =>
  page.locator('button#send-event-button');

const sendEventFullscreen = (page: Page) =>
  page.locator('dialog#send-event-fullscreen[open]');

const handlerSelect = (page: Page) =>
  page.locator('select#send-event-fullscreen-form_handler');

const eventInput = (page: Page) =>
  page.locator('input#send-event-fullscreen-form_event');

const codeMirrorTextbox = (page: Page) =>
  page.locator('div.cm-content[role="textbox"]');

const sendButton = (page: Page) =>
  page.locator('dialog#send-event-fullscreen button[type="submit"]');

test('user can send events to LiveView and LiveComponent', async ({
  dbgApp,
}) => {
  await expect(findSidebarBasicInfo(dbgApp)).toBeVisible();
  await expect(findAssignsEntry(dbgApp, 'counter', '0')).toBeVisible();

  await sendEventButton(dbgApp).click();
  await expect(sendEventFullscreen(dbgApp)).toBeVisible();
  await handlerSelect(dbgApp).selectOption('handle_info/2');
  await codeMirrorTextbox(dbgApp).fill(':increment');
  await sendButton(dbgApp).click();

  await expect(sendEventFullscreen(dbgApp)).not.toBeVisible();
  await expect(findAssignsEntry(dbgApp, 'counter', '1')).toBeVisible();

  await findComponentTreeNode(dbgApp, 5).click();
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();

  await sendEventButton(dbgApp).click();
  await expect(sendEventFullscreen(dbgApp)).toBeVisible();
  await handlerSelect(dbgApp).selectOption('handle_event/3');
  await eventInput(dbgApp).fill('show_child');
  await sendButton(dbgApp).click();

  await expect(sendEventFullscreen(dbgApp)).not.toBeVisible();
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'true')).toBeVisible();

  await sendEventButton(dbgApp).click();
  await expect(sendEventFullscreen(dbgApp)).toBeVisible();
  await handlerSelect(dbgApp).selectOption('update/2');
  await codeMirrorTextbox(dbgApp).fill('%{show_child?: false}');
  await sendButton(dbgApp).click();

  await expect(sendEventFullscreen(dbgApp)).not.toBeVisible();
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();
});
