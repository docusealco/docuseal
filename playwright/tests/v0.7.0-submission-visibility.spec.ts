import { test, expect } from '@playwright/test';
import { loginAs, adminEmail, adminPassword } from './helpers/auth';

// Phase 1.3 — Submission visibility (signer-only).
// A submission is only visible to:
//  - the user who created it, OR
//  - a user whose email matches a submitter on the submission.
// Applies to all roles, including admin.
//
// Requires a second admin user pre-seeded:
//   - admin2@example.com / password  (same account as the primary admin)

const secondAdminEmail = process.env.DOCUSEAL_ADMIN2_EMAIL || 'admin2@example.com';
const secondAdminPassword = process.env.DOCUSEAL_ADMIN2_PASSWORD || 'password';

test.describe('Submission visibility', () => {
  test("another admin in the same account cannot see user A's submissions", async ({
    browser,
  }) => {
    const ctxA = await browser.newContext();
    const pageA = await ctxA.newPage();
    await loginAs(pageA, adminEmail, adminPassword);
    await pageA.goto('/submissions');
    // Capture the first submission's visible text (if any) as a probe.
    const firstRow = pageA.locator('table tbody tr').first();
    const hasSubmission = (await firstRow.count()) > 0;
    const probeText = hasSubmission ? (await firstRow.innerText()).split('\n')[0] : null;
    await ctxA.close();

    const ctxB = await browser.newContext();
    const pageB = await ctxB.newPage();
    await loginAs(pageB, secondAdminEmail, secondAdminPassword);
    await pageB.goto('/submissions');
    if (probeText) {
      await expect(pageB.getByText(probeText)).toHaveCount(0);
    }
    await ctxB.close();
  });
});
