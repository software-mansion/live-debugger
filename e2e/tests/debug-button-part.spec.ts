import { test, expect } from '@playwright/test';

test('debug button position can be customized via ::part(debug-button)', async ({
  page,
}) => {
  await page.goto('/');

  const button = page.locator('#live-debugger-debug-button');

  await expect(button).toHaveCSS('bottom', '20px');
  await expect(button).toHaveCSS('right', '20px');

  // Page CSS targeting the shadow part overrides the default position
  await page.addStyleTag({
    content: `
      #live-debugger::part(debug-button) {
        bottom: auto;
        right: auto;
        top: 16px;
        left: 16px;
      }
    `,
  });

  await expect(button).toHaveCSS('top', '16px');
  await expect(button).toHaveCSS('left', '16px');

  await button.click();
  await page.locator('#live-debugger-debug-tooltip-move-button').click();
  await page.mouse.move(300, 200);
  await button.click();

  await expect(button).toHaveCSS('top', '180px');
  await expect(button).toHaveCSS('left', '280px');

  await page.setViewportSize({ width: 250, height: 150 });

  await expect(button).toHaveCSS('top', '16px');
  await expect(button).toHaveCSS('left', '16px');
});
