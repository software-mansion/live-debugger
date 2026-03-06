import { prepareDevDebuggerPairTest, expect, Page } from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/embedded');

const findCurrentNodeModule = (page: Page) =>
  page.locator('#node-inspector-basic-info-current-node-module');

test('user can see all associated LiveViews to currently debugged LiveView', async ({
  devApp,
  dbgApp,
}) => {
  await expect(findCurrentNodeModule(dbgApp)).toHaveText(
    'LiveDebuggerDev.LiveViews.Embedded'
  );

  await expect(dbgApp.locator('#associated-live-views button')).toHaveCount(6);

  const nestedLiveViewNode = dbgApp
    .getByRole('button', { name: 'LiveDebuggerDev.LiveViews.Nested' })
    .first();

  await nestedLiveViewNode.hover();
  await nestedLiveViewNode.click();

  await expect(findCurrentNodeModule(dbgApp)).toHaveText(
    'LiveDebuggerDev.LiveViews.Nested'
  );

  const showToggleButton = devApp.getByRole('button', { name: 'Show' }).nth(3);

  await showToggleButton.click();

  await expect(dbgApp.locator('#associated-live-views button')).toHaveCount(7);

  await showToggleButton.click();

  await expect(dbgApp.locator('#associated-live-views button')).toHaveCount(6);
});
