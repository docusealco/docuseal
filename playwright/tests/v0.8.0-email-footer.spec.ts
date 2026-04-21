import { test, expect } from '@playwright/test';
import { loginAsAdmin } from './helpers/auth';

// Phase 2.1 — Global email footer.
// Sets a footer via Notifications settings and verifies it saves.
// Actual mail rendering is validated manually with letter_opener in dev.

test.describe('Email footer', () => {
  test('admin can configure an email footer message', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/settings/notifications');

    const textarea = page.locator('textarea[name="account_config[value]"]').first();
    await expect(textarea).toBeVisible();

    const footer = `CONFIDENTIAL - ${Date.now()}`;
    await textarea.fill(footer);
    await page.getByRole('button', { name: /save|update/i }).first().click();
    await page.waitForLoadState('networkidle');

    // Reload and ensure the saved footer persists.
    await page.goto('/settings/notifications');
    await expect(page.locator('textarea').filter({ hasText: footer }).first()).toBeVisible();
  });
});
