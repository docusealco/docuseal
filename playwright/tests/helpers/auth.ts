import { Page, expect } from '@playwright/test';

// Credentials come from env so tests work against any environment.
export const adminEmail = process.env.DOCUSEAL_ADMIN_EMAIL || 'admin@example.com';
export const adminPassword = process.env.DOCUSEAL_ADMIN_PASSWORD || 'password';

export async function loginAs(page: Page, email: string, password: string): Promise<void> {
  await page.goto('/users/sign_in');
  await page.getByLabel(/email/i).fill(email);
  await page.getByLabel(/password/i).fill(password);
  await page.getByRole('button', { name: /sign in|log in/i }).click();
  await expect(page).not.toHaveURL(/sign_in/);
}

export async function loginAsAdmin(page: Page): Promise<void> {
  await loginAs(page, adminEmail, adminPassword);
}
