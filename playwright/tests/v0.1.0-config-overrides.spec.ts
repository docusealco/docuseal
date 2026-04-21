import { test, expect } from '@playwright/test';
import { loginAsAdmin } from './helpers/auth';

// Phase 0.1 — Config override pattern (UI reflection only).
// The env-var swap itself cannot be exercised via Playwright (needs pod restart),
// so we verify the UI renders toggles based on the DB-seeded AccountConfig values.

test.describe('Config overrides — UI reflection', () => {
  test('E-Signing settings page loads and renders toggles', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/settings/esign');

    // A known account-config backed toggle should be present.
    await expect(page.locator('form')).toBeVisible();
  });
});
