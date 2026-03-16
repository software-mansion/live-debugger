/**
 * Warm-up that verifies the tracing infrastructure is fully initialized.
 *
 * TracingManager.handle_continue(:setup_tracing) runs asynchronously after app boot.
 * We open a dev app + debugger pair and check if traces were captured.
 * If not, we wait 5s for TracingManager to finish initializing before tests run.
 */
import { chromium } from '@playwright/test';

export default async function globalSetup() {
  const browser = await chromium.launch();
  const page = await browser.newPage();

  await page.goto('http://localhost:4005/');

  await page.locator('#live-debugger-debug-button').click();
  const dbgAppPromise = page.waitForEvent('popup');
  await page.getByText('Open in new tab').click();
  const dbgApp = await dbgAppPromise;

  for (let i = 0; i < 5; i++) {
    try {
      await dbgApp
        .locator('#traces-list-stream details')
        .waitFor({ timeout: 2000 });
      break;
    } catch {
      await page.locator('#increment-button').click();
    }
  }

  await browser.close();
}
