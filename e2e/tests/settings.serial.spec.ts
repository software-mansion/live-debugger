import { test, expect } from '@playwright/test';

test.describe('settings', { tag: '@settings' }, () => {
  test('dead view mode is togglable', async ({ page: devApp, context }) => {
    await devApp.goto('/');
    await devApp.locator('#live-debugger-debug-button').click();
    const dbgAppPromise = devApp.waitForEvent('popup');
    await devApp.getByText('Open in new tab').click();
    const dbgApp1 = await dbgAppPromise;

    const dbgApp2 = await context.newPage();
    await dbgApp2.goto('http://localhost:4008/settings');

    await expect(dbgApp1.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp1.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await devApp.getByRole('link', { name: 'Side' }).click();

    await expect(dbgApp1.getByRole('document')).toContainText('Disconnected');
    await expect(dbgApp1.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await dbgApp1.getByRole('button', { name: 'Continue' }).click();

    await expect(dbgApp1.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp1.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Side'
    );

    await dbgApp1.getByRole('link', { name: 'Icon settings' }).click();

    await expect(
      dbgApp1.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked();

    await expect(
      dbgApp2.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked();

    await dbgApp1
      .locator('label:has(input[phx-value-setting=\"dead_view_mode\"])')
      .click();

    await expect(
      dbgApp1.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked({ checked: false });

    await expect(
      dbgApp2.locator('input[phx-value-setting="dead_view_mode"]')
    ).toBeChecked({ checked: false });

    await dbgApp1.getByRole('link', { name: 'Icon arrow left' }).click();

    await expect(dbgApp1.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp1.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Side'
    );

    await devApp.getByRole('link', { name: 'Main' }).click();

    await expect(dbgApp1.getByRole('document')).toContainText('Monitored PID');
    await expect(dbgApp1.getByRole('document')).toContainText(
      'LiveDebuggerDev.LiveViews.Main'
    );

    await dbgApp1.getByRole('link', { name: 'Icon settings' }).click();
    await dbgApp1
      .locator('label:has(input[phx-value-setting=\"dead_view_mode\"])')
      .click();
  });
});
