import { test, expect } from '@playwright/test';

test('debug button position can be customized via ::part(debug-button)', async ({
  page,
}) => {
  await page.goto('/');

  const button = page.locator('#live-debugger-debug-button');
  await expect(button).toBeVisible();

  // Default position: bottom-right, 20px offsets
  const defaultBox = (await button.boundingBox())!;
  const viewport = page.viewportSize()!;
  expect(defaultBox.x + defaultBox.width).toBe(viewport.width - 20);
  expect(defaultBox.y + defaultBox.height).toBe(viewport.height - 20);

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

  const movedBox = (await button.boundingBox())!;
  expect(movedBox.x).toBe(16);
  expect(movedBox.y).toBe(16);
});
