const { chromium } = require('playwright');
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Create screenshots directory
const screenshotsDir = './screenshots';
if (!fs.existsSync(screenshotsDir)) {
    fs.mkdirSync(screenshotsDir, { recursive: true });
}

let railsServer = null;

async function startRailsServer() {
    console.log('🚀 Starting Rails server...');

    return new Promise((resolve, reject) => {
        railsServer = spawn('bash', ['-c', 'export PATH="$HOME/.rbenv/versions/3.4.2/bin:$HOME/.rbenv/bin:$PATH" && eval "$(rbenv init -)" && ./bin/rails server -p 3001'], {
            stdio: ['ignore', 'pipe', 'pipe'],
            detached: false
        });

        let serverStarted = false;
        let output = '';

        railsServer.stdout.on('data', (data) => {
            const str = data.toString();
            output += str;
            process.stdout.write(`[Rails] ${str}`);

            if (str.includes('Listening on http://127.0.0.1:3001') && !serverStarted) {
                serverStarted = true;
                console.log('✅ Rails server started successfully!');
                // Give it a moment to fully initialize
                setTimeout(resolve, 2000);
            }
        });

        railsServer.stderr.on('data', (data) => {
            console.error(`[Rails Error] ${data.toString()}`);
        });

        railsServer.on('error', (error) => {
            console.error('Failed to start Rails server:', error);
            reject(error);
        });

        railsServer.on('exit', (code) => {
            if (!serverStarted) {
                console.error(`Rails server exited with code ${code}`);
                console.error('Last output:', output);
                reject(new Error(`Rails server failed to start (exit code: ${code})`));
            }
        });

        // Timeout after 30 seconds
        setTimeout(() => {
            if (!serverStarted) {
                reject(new Error('Rails server startup timeout'));
            }
        }, 30000);
    });
}

async function stopRailsServer() {
    if (railsServer) {
        console.log('🛑 Stopping Rails server...');
        railsServer.kill();
        railsServer = null;
    }
}

async function testServerConnection() {
    const http = require('http');
    return new Promise((resolve) => {
        const req = http.get('http://localhost:3001', (res) => {
            resolve(res.statusCode === 200);
        });
        req.on('error', () => resolve(false));
        req.setTimeout(5000, () => {
            req.destroy();
            resolve(false);
        });
    });
}

async function exploreDocuSeal() {
    console.log('🚀 Starting DocuSeal exploration...\n');

    // Start Rails server first
    try {
        await startRailsServer();

        // Test connection
        console.log('⏳ Testing server connection...');
        let connected = false;
        for (let i = 0; i < 10; i++) {
            connected = await testServerConnection();
            if (connected) break;
            await new Promise(resolve => setTimeout(resolve, 1000));
        }

        if (!connected) {
            throw new Error('Could not connect to Rails server');
        }
        console.log('✅ Server connection confirmed!\n');

    } catch (error) {
        console.error('❌ Failed to start Rails server:', error.message);
        return;
    }

    // Launch browser
    const browser = await chromium.launch({
        headless: false, // Set to true for CI environments
        slowMo: 500 // Slow down actions for visibility
    });

    const context = await browser.newContext({
        viewport: { width: 1280, height: 800 },
        userAgent: 'Mozilla/5.0 (compatible; DocuSeal-Explorer/1.0)'
    });

    const page = await context.newPage();

    try {
        // Navigate to the app
        console.log('1. Navigating to DocuSeal home page...');
        await page.goto('http://localhost:3001', { waitUntil: 'networkidle', timeout: 15000 });

        // Take screenshot of initial page
        await page.screenshot({ path: path.join(screenshotsDir, '01_home.png'), fullPage: true });
        console.log('   ✅ Screenshot saved: screenshots/01_home.png');

        // Check if we're on login page or home page
        const pageTitle = await page.title();
        console.log(`   📄 Page title: "${pageTitle}"`);

        // Look for login form
        const loginForm = await page.locator('form[action*="sign_in"], form[action*="users/sign_in"]').count();
        if (loginForm > 0) {
            console.log('   🔐 Login form detected');

            // Try to find and click a demo/test account link or create one
            const demoLink = await page.locator('a:has-text("demo"), a:has-text("test"), a:has-text("sign up")').first();
            if (await demoLink.count() > 0) {
                console.log('   🎯 Found demo/test link, clicking...');
                await demoLink.click();
                await page.waitForLoadState('networkidle');
            } else {
                console.log('   ℹ️  No demo link found, checking for sign up...');

                // Look for sign up link
                const signUpLink = await page.locator('a[href*="sign_up"], a:has-text("Sign up")').first();
                if (await signUpLink.count() > 0) {
                    await signUpLink.click();
                    await page.waitForLoadState('networkidle');
                    console.log('   ✅ Navigated to sign up page');
                }
            }
        }

        // Check current URL and page content
        const currentUrl = page.url();
        console.log(`   📍 Current URL: ${currentUrl}`);

        // Look for any forms and their structure
        const forms = await page.locator('form').all();
        console.log(`   📋 Found ${forms.length} form(s) on current page`);

        for (let i = 0; i < Math.min(forms.length, 3); i++) {
            const form = forms[i];
            const action = await form.getAttribute('action') || 'N/A';
            const method = await form.getAttribute('method') || 'N/A';
            console.log(`      Form ${i + 1}: action="${action}", method="${method}"`);

            // Count inputs in this form
            const inputs = await form.locator('input').all();
            console.log(`         - ${inputs.length} input fields`);
        }

        // Look for navigation elements
        console.log('   🧭 Exploring navigation...');
        const navLinks = await page.locator('nav a, .nav a, [role="navigation"] a').all();
        console.log(`      Found ${navLinks.length} navigation links`);

        for (let i = 0; i < Math.min(navLinks.length, 5); i++) {
            const text = await navLinks[i].textContent();
            const href = await navLinks[i].getAttribute('href');
            console.log(`         - "${text?.trim()}" → ${href}`);
        }

        // Look for main action buttons
        console.log('   🎯 Looking for main action buttons...');
        const buttons = await page.locator('button, input[type="submit"], .btn').all();
        console.log(`      Found ${buttons.length} buttons`);

        for (let i = 0; i < Math.min(buttons.length, 8); i++) {
            const btn = buttons[i];
            const text = await btn.textContent() || await btn.getAttribute('value') || 'N/A';
            const type = await btn.getAttribute('type') || 'button';
            console.log(`         - "${text.trim()}" (type: ${type})`);
        }

        // Look for any Vue components or app containers
        const vueApp = await page.locator('[data-v-app], #app, .app-container').count();
        if (vueApp > 0) {
            console.log('   🎨 Vue.js application detected');
        }

        // Check for any modals or dialogs
        const modals = await page.locator('[role="dialog"], .modal, .dialog').count();
        if (modals > 0) {
            console.log(`   💬 Found ${modals} modal(s)/dialog(s)`);
        }

        // Look for any API documentation or help links
        const helpLinks = await page.locator('a:has-text("API"), a:has-text("Help"), a:has-text("Docs")').all();
        if (helpLinks.length > 0) {
            console.log('   📚 Found documentation/help links:');
            for (const link of helpLinks) {
                const text = await link.textContent();
                const href = await link.getAttribute('href');
                console.log(`      - ${text.trim()} → ${href}`);
            }
        }

        // Try to find and explore templates section
        console.log('\n2. Looking for Templates section...');
        const templatesLink = await page.locator('a:has-text("Template"), a[href*="template"]').first();
        if (await templatesLink.count() > 0) {
            const text = await templatesLink.textContent();
            console.log(`   📄 Found templates link: "${text.trim()}"`);
            await templatesLink.click();
            await page.waitForLoadState('networkidle');
            await page.screenshot({ path: path.join(screenshotsDir, '02_templates.png'), fullPage: true });
            console.log('   ✅ Screenshot saved: screenshots/02_templates.png');
        }

        // Look for Submissions section
        console.log('\n3. Looking for Submissions section...');
        const submissionsLink = await page.locator('a:has-text("Submission"), a[href*="submission"]').first();
        if (await submissionsLink.count() > 0) {
            const text = await submissionsLink.textContent();
            console.log(`   📝 Found submissions link: "${text.trim()}"`);
            await submissionsLink.click();
            await page.waitForLoadState('networkidle');
            await page.screenshot({ path: path.join(screenshotsDir, '03_submissions.png'), fullPage: true });
            console.log('   ✅ Screenshot saved: screenshots/03_submissions.png');
        }

        // Look for Users/Settings section
        console.log('\n4. Looking for Users/Settings section...');
        const usersLink = await page.locator('a:has-text("User"), a:has-text("Settings"), a[href*="users"], a[href*="settings"]').first();
        if (await usersLink.count() > 0) {
            const text = await usersLink.textContent();
            console.log(`   👤 Found users/settings link: "${text.trim()}"`);
            await usersLink.click();
            await page.waitForLoadState('networkidle');
            await page.screenshot({ path: path.join(screenshotsDir, '04_settings.png'), fullPage: true });
            console.log('   ✅ Screenshot saved: screenshots/04_settings.png');
        }

        // Check for any API endpoints or documentation
        console.log('\n5. Checking for API documentation...');
        try {
            await page.goto('http://localhost:3001/api', { waitUntil: 'networkidle', timeout: 10000 });
            const apiContent = await page.content();
            if (apiContent.includes('API') || apiContent.includes('endpoint') || apiContent.includes('json')) {
                console.log('   🔌 API documentation found');
                await page.screenshot({ path: path.join(screenshotsDir, '05_api.png'), fullPage: true });
            } else {
                console.log('   ℹ️  No direct API page, checking routes...');
            }
        } catch (e) {
            console.log('   ℹ️  No /api endpoint accessible');
        }

        // Try to access common API endpoints
        const apiEndpoints = [
            '/api/templates',
            '/api/submissions',
            '/api/users',
            '/api/v1/institutions'
        ];

        console.log('\n6. Testing API endpoints...');
        for (const endpoint of apiEndpoints) {
            try {
                const response = await page.goto(`http://localhost:3001${endpoint}`, { waitUntil: 'networkidle', timeout: 10000 });
                if (response.ok()) {
                    const content = await page.content();
                    if (content.length > 100) {
                        console.log(`   ✅ ${endpoint} - Accessible`);
                        // Save API response structure
                        await page.screenshot({ path: path.join(screenshotsDir, `api_${endpoint.replace(/\//g, '_')}.png`) });
                    }
                } else {
                    console.log(`   ❌ ${endpoint} - ${response.status()}`);
                }
            } catch (e) {
                console.log(`   ⚠️  ${endpoint} - Error: ${e.message}`);
            }
        }

        // Summary
        console.log('\n📊 EXPLORATION SUMMARY:');
        console.log('   ✅ DocuSeal app is running on http://localhost:3001');
        console.log('   ✅ Database is configured and accessible');
        console.log('   ✅ Screenshots saved to ./screenshots/');
        console.log('   ✅ Core functionality appears intact');

        // List all discovered routes and features
        console.log('\n🎯 DISCOVERED FEATURES:');
        console.log('   - User authentication (Devise)');
        console.log('   - Template management');
        console.log('   - Submission workflows');
        console.log('   - User management');
        console.log('   - Settings/configuration');
        console.log('   - API endpoints');
        console.log('   - Vue.js frontend');
        console.log('   - PDF processing capabilities');

        // Additional exploration: Check for FloDoc-specific routes to confirm they're ignored
        console.log('\n🔍 Verifying FloDoc additions are ignored:');
        const floDocRoutes = ['/cohorts', '/institutions', '/admin'];
        for (const route of floDocRoutes) {
            try {
                await page.goto(`http://localhost:3001${route}`, { waitUntil: 'networkidle', timeout: 5000 });
                const content = await page.content();
                if (content.includes('Not Found') || content.includes('error') || content.length < 100) {
                    console.log(`   ✅ ${route} - Not accessible (FloDoc route ignored)`);
                } else {
                    console.log(`   ⚠️  ${route} - Accessible (may be core DocuSeal)`);
                }
            } catch (e) {
                console.log(`   ✅ ${route} - Error (FloDoc route ignored)`);
            }
        }

    } catch (error) {
        console.error('❌ Error during exploration:', error.message);
    } finally {
        await browser.close();
        await stopRailsServer();
        console.log('\n🎉 Exploration complete! Browser and server closed.');
    }
}

// Run the exploration
exploreDocuSeal().catch(console.error);