import { test, expect } from '@playwright/test';
import { loginAsAdmin } from './helpers/auth';

// Phase 0.3 — UI visibility preferences.
// Toggle "Show Console Link" off and verify the console link disappears.

test.describe('UI visibility preferences', () => {
  test('toggling Show Console Link hides and shows the link', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/settings/personalization');

    const consoleToggle = page.locator('form input[type="hidden"][value="show_console_link"]').locator('..')
      .locator('input[type="checkbox"]');
    await expect(consoleToggle).toBeVisible();

    const initiallyChecked = await consoleToggle.isChecked();

    // Toggle off
    if (initiallyChecked) {
      await consoleToggle.click();
      await page.waitForLoadState('networkidle');
    }

    await page.goto('/');
    // Open user-menu dropdown
    await page.locator('.dropdown label').first().click();
    await expect(page.getByRole('link', { name: /console/i })).toHaveCount(0);

    // Toggle back on
    await page.goto('/settings/personalization');
    const toggle2 = page.locator('form input[type="hidden"][value="show_console_link"]').locator('..')
      .locator('input[type="checkbox"]');
    if (!(await toggle2.isChecked())) {
      await toggle2.click();
      await page.waitForLoadState('networkidle');
    }

    await page.goto('/settings/profile');
    // With Console link enabled and admin signed in, the Console link should appear
    // in the settings sidebar when not in multitenant mode.
    await expect(page.getByRole('link', { name: /console/i }).first()).toBeVisible();
  });
});
