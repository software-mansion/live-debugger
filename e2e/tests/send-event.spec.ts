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

const dispatchEvent = async (
  page: Page,
  handler: string,
  opts: { event?: string; payload?: string }
) => {
  await sendEventButton(page).click();
  await expect(sendEventFullscreen(page)).toBeVisible();
  await handlerSelect(page).selectOption(handler);
  if (opts.event) {
    await eventInput(page).fill(opts.event);
  }
  if (opts.payload) {
    await codeMirrorTextbox(page).fill(opts.payload);
  }
  await sendButton(page).click();
  await expect(sendEventFullscreen(page)).not.toBeVisible();
};

test('user can send events to LiveView and LiveComponent', async ({
  dbgApp,
}) => {
  await expect(findSidebarBasicInfo(dbgApp)).toBeVisible();
  await expect(findAssignsEntry(dbgApp, 'counter', '0')).toBeVisible();

  await dispatchEvent(dbgApp, 'handle_info/2', { payload: ':increment' });
  await expect(findAssignsEntry(dbgApp, 'counter', '1')).toBeVisible();

  await findComponentTreeNode(dbgApp, 5).click();
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();

  await dispatchEvent(dbgApp, 'handle_event/3', { event: 'show_child' });
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'true')).toBeVisible();

  await dispatchEvent(dbgApp, 'update/2', { payload: '%{show_child?: false}' });
  await expect(findAssignsEntry(dbgApp, 'show_child?', 'false')).toBeVisible();
});
