const { chromium } = require('playwright');
const fs = require('fs');

async function testPDFWorkflow() {
    console.log('🚀 Testing FloDoc PDF workflow with ngrok...\n');

    const browser = await chromium.launch({
        headless: true,
        args: ['--no-sandbox', '--disable-setuid-sandbox']
    });

    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 },
        acceptDownloads: true
    });

    const page = await context.newPage();

    // Capture console errors
    page.on('console', msg => {
        const type = msg.type();
        if (type === 'error' || type === 'warning') {
            console.log(`   [${type}] ${msg.text()}`);
        }
    });

    // Capture network failures
    page.on('requestfailed', request => {
        console.log(`   ❌ Network failed: ${request.url()} - ${request.failure()?.errorText}`);
    });

    try {
        // Test 1: Check if ngrok URL is accessible
        console.log('1. Testing ngrok connectivity...');
        try {
            const response = await page.goto('https://pseudoancestral-expressionlessly-calista.ngrok-free.dev', {
                waitUntil: 'networkidle',
                timeout: 10000
            });
            console.log(`   ✅ Ngrok URL accessible: ${response.status()}`);
        } catch (e) {
            console.log(`   ❌ Ngrok URL failed: ${e.message}`);
            console.log('   Falling back to localhost...');
            await page.goto('http://localhost:3001', { waitUntil: 'networkidle' });
            console.log('   ✅ Localhost accessible');
        }

        // Test 2: Check if we need to log in
        console.log('\n2. Checking authentication status...');
        const currentUrl = page.url();
        const pageContent = await page.content();

        if (pageContent.includes('Sign in') || pageContent.includes('sign_in')) {
            console.log('   ⚠️  Login required - checking for existing session...');

            // Try to find login form
            const emailField = await page.$('input[type="email"], input[name*="email"]');
            if (emailField) {
                console.log('   ❌ No active session found. Please log in manually first.');
                console.log('   URL:', page.url());
                console.log('   You can use the existing credentials or create a test account.');
                await browser.close();
                return;
            }
        }

        console.log('   ✅ Authentication appears to be working');

        // Test 3: Navigate to submissions or templates
        console.log('\n3. Looking for submissions/templates...');

        // Try different navigation paths
        const pathsToTry = [
            '/submissions',
            '/templates',
            '/dashboard',
            '/'
        ];

        let foundContent = false;

        for (const path of pathsToTry) {
            try {
                await page.goto(`http://localhost:3001${path}`, { waitUntil: 'networkidle', timeout: 5000 });
                const content = await page.content();

                if (content.includes('submission') || content.includes('template') || content.includes('FloDoc')) {
                    console.log(`   ✅ Found content at ${path}`);
                    foundContent = true;
                    break;
                }
            } catch (e) {
                // Skip to next path
            }
        }

        if (!foundContent) {
            console.log('   ❌ Could not find submissions or templates');
            console.log('   Current URL:', page.url());
            console.log('   Page title:', await page.title());
        }

        // Test 4: Look for any PDF download functionality
        console.log('\n4. Searching for PDF download functionality...');

        // Look for download links/buttons
        const downloadSelectors = [
            'a[href*="download"]',
            'button:has-text("Download")',
            'a:has-text("PDF")',
            'button:has-text("PDF")',
            'a[href*=".pdf"]',
            'a[href*="/s/"]', // submission links
            'a[href*="/submitters/"]'
        ];

        let downloadLinks = [];
        for (const selector of downloadSelectors) {
            try {
                const links = await page.$$(selector);
                if (links.length > 0) {
                    console.log(`   Found ${links.length} links with selector: ${selector}`);
                    downloadLinks.push(...links);
                }
            } catch (e) {
                // Ignore selector errors
            }
        }

        if (downloadLinks.length > 0) {
            console.log(`   ✅ Total download-related links found: ${downloadLinks.length}`);

            // Try the first download link
            console.log('\n5. Attempting to download PDF...');
            const firstLink = downloadLinks[0];
            const linkText = (await firstLink.textContent()).trim();
            const linkHref = await firstLink.getAttribute('href');

            console.log(`   Trying link: "${linkText}" -> ${linkHref}`);

            // Set up download handler
            const downloadPromise = page.waitForEvent('download').catch(() => null);

            await firstLink.click();

            const download = await downloadPromise;

            if (download) {
                const filename = download.suggestedFilename() || 'download.pdf';
                const downloadPath = `/tmp/${filename}`;

                try {
                    await download.saveAs(downloadPath);
                    const stats = fs.statSync(downloadPath);

                    console.log(`   ✅ Download successful!`);
                    console.log(`   File: ${filename}`);
                    console.log(`   Size: ${stats.size} bytes`);
                    console.log(`   Path: ${downloadPath}`);

                    if (stats.size > 1000) {
                        console.log('   ✅ PDF appears to be valid (good file size)');
                    } else {
                        console.log('   ⚠️  PDF might be corrupted (small file size)');
                    }
                } catch (saveError) {
                    console.log(`   ❌ Failed to save download: ${saveError.message}`);
                }
            } else {
                console.log('   ❌ Download did not start');

                // Check if it opened in new tab instead
                const newUrl = page.url();
                if (newUrl !== linkHref && newUrl.includes('pdf')) {
                    console.log('   ⚠️  PDF might have opened in current tab instead');

                    // Try to save the current page as PDF
                    try {
                        const pdfBuffer = await page.pdf({ format: 'A4' });
                        const pdfPath = '/tmp/page_capture.pdf';
                        fs.writeFileSync(pdfPath, pdfBuffer);
                        console.log(`   ✅ Captured current page as PDF: ${pdfPath} (${pdfBuffer.length} bytes)`);
                    } catch (pdfError) {
                        console.log(`   ❌ Failed to capture page as PDF: ${pdfError.message}`);
                    }
                }
            }
        } else {
            console.log('   ❌ No download links found on current page');

            // Let's see what's actually on the page
            console.log('\n6. Analyzing page content...');
            const allLinks = await page.$$('a');
            console.log(`   Total links on page: ${allLinks.length}`);

            // Show first 5 links
            for (let i = 0; i < Math.min(5, allLinks.length); i++) {
                const link = allLinks[i];
                const text = (await link.textContent()).trim();
                const href = await link.getAttribute('href');
                if (text && href) {
                    console.log(`   Link ${i + 1}: "${text}" -> ${href}`);
                }
            }
        }

        // Test 7: Try direct API access
        console.log('\n7. Testing direct API endpoints...');
        const apiTests = [
            '/api/v1/submissions',
            '/api/v1/templates'
        ];

        for (const endpoint of apiTests) {
            try {
                const response = await page.goto(`http://localhost:3001${endpoint}`, {
                    waitUntil: 'networkidle',
                    timeout: 5000
                });
                const status = response.status();
                const body = await page.textContent('body');

                if (status === 200 && body.length > 0) {
                    console.log(`   ✅ ${endpoint}: ${status} (${body.length} chars)`);
                } else {
                    console.log(`   ⚠️  ${endpoint}: ${status}`);
                }
            } catch (e) {
                console.log(`   ❌ ${endpoint}: ${e.message}`);
            }
        }

    } catch (error) {
        console.error('\n❌ Test failed:', error.message);
        console.error('Stack:', error.stack);
    } finally {
        console.log('\n8. Closing browser...');
        await browser.close();
        console.log('\n🔍 Test complete!');
    }
}

// Run the test
testPDFWorkflow().then(() => {
    process.exit(0);
}).catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});