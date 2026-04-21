import { test, expect } from '@playwright/test';
import { loginAsAdmin } from './helpers/auth';

// Phase 0.2 — External SMTP via env vars.
// Default state (no env override): form fields are editable.

test.describe('External SMTP', () => {
  test('SMTP settings form is editable when no env override is set', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/settings/email');

    const host = page.locator('input[name="encrypted_config[value][host]"]');
    await expect(host).toBeVisible();
    await expect(host).toBeEditable();
  });
});
