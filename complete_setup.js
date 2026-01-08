const { chromium } = require('playwright');

async function completeSetup() {
    console.log('🚀 Starting DocuSeal setup completion...\n');

    const browser = await chromium.launch({
        headless: false, // Set to true for CI
        slowMo: 500
    });

    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 },
        userAgent: 'Mozilla/5.0 (compatible; DocuSeal-Setup/1.0)'
    });

    const page = await context.newPage();

    // Capture console errors
    page.on('console', msg => {
        if (msg.type() === 'error') {
            console.log('❌ Browser Console Error:', msg.text());
        } else if (msg.type() === 'warning') {
            console.log('⚠️ Browser Console Warning:', msg.text());
        }
    });

    // Capture page errors
    page.on('pageerror', error => {
        console.log('❌ Page Error:', error.message);
    });

    // Capture network errors
    page.on('requestfailed', request => {
        console.log('❌ Network Request Failed:', request.url());
    });

    try {
        // Step 1: Navigate to setup page
        console.log('1. Navigating to setup page...');
        await page.goto('http://localhost:3001/setup', { waitUntil: 'networkidle' });

        // Take initial screenshot
        await page.screenshot({ path: 'screenshots/setup_initial.png', fullPage: true });
        console.log('   ✅ Setup page loaded');

        // Step 2: Analyze form structure
        console.log('\n2. Analyzing form structure...');
        const form = await page.locator('form').first();
        const formAction = await form.getAttribute('action') || '/setup';
        const formMethod = await form.getAttribute('method') || 'POST';
        console.log(`   📋 Form: ${formMethod} ${formAction}`);

        // Step 3: Find all form fields
        console.log('\n3. Finding form fields...');
        const inputs = await page.locator('input').all();
        const fields = {};

        for (const input of inputs) {
            const name = await input.getAttribute('name');
            const type = await input.getAttribute('type');
            const id = await input.getAttribute('id');
            const placeholder = await input.getAttribute('placeholder');

            if (name) {
                fields[name] = { type, id, placeholder };
                console.log(`   📝 ${name} (${type})${placeholder ? ` - "${placeholder}"` : ''}`);
            }
        }

        // Step 4: Check for CSRF token
        const csrfToken = await page.locator('input[name="authenticity_token"]').first();
        if (await csrfToken.count() > 0) {
            console.log('   ✅ CSRF token found');
        } else {
            console.log('   ⚠️  No CSRF token found');
        }

        // Step 5: Fill the form
        console.log('\n4. Filling setup form...');

        // User fields
        await page.fill('input[name="user[first_name]"]', 'Admin');
        await page.fill('input[name="user[last_name]"]', 'User');
        await page.fill('input[name="user[email]"]', 'admin@example.com');
        await page.fill('input[name="user[password]"]', 'SecurePassword123!');

        // Account fields
        await page.fill('input[name="account[name]"]', 'Test Organization');
        await page.fill('input[name="account[timezone]"]', 'UTC');
        await page.fill('input[name="account[locale]"]', 'en');

        // EncryptedConfig (app URL)
        await page.fill('input[name="encrypted_config[value]"]', 'http://localhost:3001');

        console.log('   ✅ Form filled with test data');

        // Step 6: Take screenshot before submission
        await page.screenshot({ path: 'screenshots/setup_filled.png', fullPage: true });

        // Step 7: Submit the form
        console.log('\n5. Submitting form...');
        await page.click('button[type="submit"], input[type="submit"]');

        // Wait for navigation or error
        try {
            await page.waitForLoadState('networkidle', { timeout: 10000 });
            console.log('   ✅ Form submitted, waiting for response...');

            // Check current URL
            const currentUrl = page.url();
            console.log(`   📍 Current URL: ${currentUrl}`);

            // Take screenshot after submission
            await page.screenshot({ path: 'screenshots/setup_result.png', fullPage: true });

            // Check for success
            if (currentUrl.includes('newsletter') || currentUrl.includes('dashboard')) {
                console.log('   ✅ Setup completed successfully!');
            } else if (currentUrl.includes('setup')) {
                console.log('   ⚠️  Still on setup page - checking for errors...');

                // Look for error messages
                const errorElements = await page.locator('.error, .alert-error, [role="alert"]').all();
                for (const error of errorElements) {
                    const text = await error.textContent();
                    console.log(`   ❌ Error: ${text.trim()}`);
                }
            }

        } catch (waitError) {
            console.log('   ⚠️  Navigation timeout - checking page state...');
            await page.screenshot({ path: 'screenshots/setup_error.png', fullPage: true });
        }

        // Step 8: Check Rails server logs for any errors
        console.log('\n6. Checking for any runtime errors...');

        // Look for any JavaScript errors on the page
        const pageContent = await page.content();
        if (pageContent.includes('error') || pageContent.includes('Error')) {
            console.log('   ⚠️  Error text found in page content');
        }

        // Step 9: Summary
        console.log('\n📊 SETUP COMPLETION SUMMARY:');
        console.log('   ✅ Navigation successful');
        console.log('   ✅ Form fields identified and filled');
        console.log('   ✅ Form submission attempted');
        console.log('   ✅ Screenshots captured');

        // List any console errors that occurred
        console.log('\n🔍 If any errors occurred above, they need to be fixed.');

    } catch (error) {
        console.error('❌ Setup failed:', error.message);
        await page.screenshot({ path: 'screenshots/setup_crash.png', fullPage: true });
    } finally {
        await browser.close();
        console.log('\n🎉 Setup exploration complete! Check screenshots/ directory for visual results.');
    }
}

completeSetup().catch(console.error);