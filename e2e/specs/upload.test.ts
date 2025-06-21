import { test, expect } from '@playwright/test';
import path from 'path';

test.describe('File upload', () => {
  test('upload pdf and ask question', async ({ page }) => {
    await page.goto('http://localhost:3080/', { timeout: 5000 });

    const filePath = path.resolve('e2e/fixtures/sample.pdf');
    await page.setInputFiles('input[type="file"]', filePath);

    const input = page.locator('form').getByRole('textbox');
    await input.fill('What is paragraph 3 about?');
    await page.locator('form').getByRole('button').nth(1).click();
    await page.waitForTimeout(3000);
    const answer = await page.locator('.text-message').last().textContent();
    expect(answer).toContain('sample');
  });
});
