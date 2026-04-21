import { test, expect } from '@playwright/test';
import { loginAs, loginAsAdmin, adminEmail, adminPassword } from './helpers/auth';

// Phase 1.1 — User roles (admin / editor / viewer)
// Pre-seeded users required in target env:
//   - editor@example.com  / password (role: editor)
//   - viewer@example.com  / password (role: viewer)

const editorEmail = process.env.DOCUSEAL_EDITOR_EMAIL || 'editor@example.com';
const viewerEmail = process.env.DOCUSEAL_VIEWER_EMAIL || 'viewer@example.com';
const defaultPassword = process.env.DOCUSEAL_DEFAULT_PASSWORD || 'password';

test.describe('User roles', () => {
  test('admin sees New Template button', async ({ page }) => {
    await loginAs(page, adminEmail, adminPassword);
    await page.goto('/');
    await expect(page.getByRole('link', { name: /new template|create/i })).toBeVisible();
  });

  test('editor can access templates but not account settings', async ({ page }) => {
    await loginAs(page, editorEmail, defaultPassword);
    await page.goto('/templates');
    await expect(page).toHaveURL(/templates|^\//);

    await page.goto('/settings/account');
    // Editor is denied write access; expect redirect or forbidden copy.
    await expect(page).not.toHaveURL(/\/settings\/account(?:$|\?)/);
  });

  test('viewer cannot see New Template / create controls', async ({ page }) => {
    await loginAs(page, viewerEmail, defaultPassword);
    await page.goto('/templates');
    await expect(page.getByRole('link', { name: /new template/i })).toHaveCount(0);
  });
});
