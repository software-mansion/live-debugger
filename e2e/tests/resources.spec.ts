import { expect, Page } from '@playwright/test';
import { prepareDevDebuggerPairTest } from './dev-dbg-test';

const test = prepareDevDebuggerPairTest('/');

const resourcesTab = (page: Page) => page.locator("a[href*='resources']").first();
const processInfoContainer = (page: Page) => page.locator('div#process-info');

const processInfoField = (page: Page, label: string) => 
  page.locator('span.font-medium', { hasText: label });

const refreshSelectBtn = (page: Page) => page.locator("button[aria-label='Refresh Rate']");
const refreshRadioBtn = (page: Page, value: number) => 
  page.locator(`input[type='radio'][value='${value}']`);

  test('user can view process information in resources tab', async ({ dbgApp }) => {
    await resourcesTab(dbgApp).click();
    await expect(processInfoContainer(dbgApp)).toBeVisible();

    const expectedFields = [
      'Initial Call',
      'Current Function',
      'Registered Name',
      'Status',
      'Message Queue Length',
      'Priority',
      'Reductions',
      'Memory',
      'Total Heap Size',
      'Stack Size',
    ];

    for (const field of expectedFields) {
      await expect(processInfoField(dbgApp, field)).toBeVisible();
    }

    await expect(refreshSelectBtn(dbgApp)).toContainText('Refresh Rate (5 s)');
    
    await refreshSelectBtn(dbgApp).click();

    await expect(refreshRadioBtn(dbgApp, 1000)).not.toBeChecked();
    await expect(refreshRadioBtn(dbgApp, 5000)).toBeChecked();
    await expect(refreshRadioBtn(dbgApp, 15000)).not.toBeChecked();
    await expect(refreshRadioBtn(dbgApp, 30000)).not.toBeChecked();

    await refreshRadioBtn(dbgApp, 1000).click();

    await expect(refreshSelectBtn(dbgApp)).toContainText('Refresh Rate (1 s)');

    await refreshSelectBtn(dbgApp).click();
    
    await expect(refreshRadioBtn(dbgApp, 1000)).toBeChecked();
    await expect(refreshRadioBtn(dbgApp, 5000)).not.toBeChecked();
    await expect(refreshRadioBtn(dbgApp, 15000)).not.toBeChecked();
});
