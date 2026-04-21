import { test, expect } from '@playwright/test';
import { loginAsAdmin } from './helpers/auth';

// Phase 0.4 — Version Display
// Assumes the app is running with APP_VERSION=v0.4.0 (kustomize configmap in UAT).

test.describe('Version display', () => {
  test('navbar shows APP_VERSION below Settings link', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/');

    const version = page.locator('#app_version');
    await expect(version).toBeVisible();
    await expect(version).toHaveText(/^v\d+\.\d+\.\d+/);
  });

  test('settings nav bottom version badge links to upstream releases', async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto('/settings/profile');

    const badge = page.locator('a[href="https://github.com/docusealco/docuseal/releases"]');
    await expect(badge).toBeVisible();
    await expect(badge).toHaveText(/^v\d+\.\d+\.\d+/);
  });
});
