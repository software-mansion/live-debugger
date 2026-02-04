import { test, expect } from '@playwright/test';

test.describe('settings', { tag: '@settings' }, () => {
  test('dead view mode is togglable', async ({ page: devApp }) => {
    await devApp.goto('/');
    await devApp.locator('#live-debugger-debug-button').click();
    const dbgAppPromise = devApp.waitForEvent('popup');
    await devApp.getByText('Open in new tab').click();
    const dbgApp = await dbgAppPromise;

    await expect(dbgApp.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await devApp.getByRole('link', { name: 'Side' }).click();

    await expect(dbgApp.getByRole('document')).toContainText('Disconnected');
    await expect(dbgApp.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await dbgApp.getByRole('button', { name: 'Continue' }).click();

    await expect(dbgApp.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Side'
    );

    await dbgApp.getByRole('link', { name: 'Icon settings' }).click();

    await expect(
      dbgApp.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked();

    await dbgApp
      .locator('label:has(input[phx-value-setting=\"dead_view_mode\"])')
      .click();

    await expect(
      dbgApp.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked({ checked: false });

    await dbgApp.getByRole('link', { name: 'Icon arrow left' }).click();

    await expect(dbgApp.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Side'
    );

    await devApp.getByRole('link', { name: 'Main' }).click();

    await expect(dbgApp.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await dbgApp.getByRole('link', { name: 'Icon settings' }).click();
    await dbgApp
      .locator('label:has(input[phx-value-setting=\"dead_view_mode\"])')
      .click();
  });
});
