import { expect, Page } from '@playwright/test';
import {
  prepareDevDebuggerPairTest,
  findNodeModuleInfo,
  findComponentTreeNode,
  setCollapsibleOpenState,
} from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/async_demo');

const asyncJobsSection = (page: Page) => page.locator('#async-jobs');

const asyncJobName = (page: Page, name: string) =>
  page.locator('#async-jobs p.font-medium', { hasText: name });

test.beforeEach(async ({ dbgApp }) => {
  await setCollapsibleOpenState(dbgApp, 'async-jobs', 'true');
  await dbgApp.reload();
});

test('user can see and track async jobs in LiveView and LiveComponent', async ({
  devApp,
  dbgApp,
}) => {
  await expect(findNodeModuleInfo(dbgApp)).toContainText('AsyncDemo');
  await expect(asyncJobsSection(dbgApp)).toBeVisible();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await devApp.locator('#start-async-button').click();
  await expect(asyncJobName(dbgApp, ':fetch_data')).toBeVisible();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await devApp.locator('#assign-async-button').click();
  await expect(
    asyncJobName(dbgApp, ':async_data1, :async_data2')
  ).toBeVisible();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await findComponentTreeNode(dbgApp, 1).click();
  await expect(findNodeModuleInfo(dbgApp)).toContainText('AsyncDemoComponent');
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await devApp.locator('#component-start-async-button').click();
  await expect(asyncJobName(dbgApp, ':component_fetch_data')).toBeVisible();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await devApp.locator('#component-assign-async-button').click();
  await expect(
    asyncJobName(dbgApp, ':component_async_data1, :component_async_data2')
  ).toBeVisible();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );

  await devApp.locator('#component-start-cancelable-async-button').click();
  await expect(
    asyncJobName(dbgApp, ':component_cancelable_fetch')
  ).toBeVisible();

  await devApp.locator('#component-cancel-async-button').click();
  await expect(asyncJobsSection(dbgApp)).toContainText(
    'No active async jobs found'
  );
});
