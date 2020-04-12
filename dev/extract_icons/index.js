const puppeteer = require('puppeteer');

const email = 'engineering@rive.app';

// This is in our 1Password, it has view only access to our Figma files. We
// could have everyone provide this in an environment variable (and change the
// value) if we don't want it in the codebase.
const password = 'cyLqEUmuV9BmLHsKRQtV';

(async () => {
    const browser = await puppeteer.launch();
    const page = await browser.newPage();

    // Go to the icon page...
    await page.goto('https://www.figma.com/file/nlGengoVlxjmxLwAfWOUoU/Rive-App?node-id=910%3A41');
    // Log us in...
    await page.type('input[name=email]', email);
    await page.type('input[name=password]', password);
    await page.click('button[type=submit]');
    await page.waitForNavigation();

    // Wait for the page to load (look for the menu)...
    await page.waitForSelector('a[data-tooltip=toggle-menu]', {
        visible: true,
    });

    // Tell the page to download files to our directory...
    await page._client.send('Page.setDownloadBehavior', {
        behavior: 'allow',
        downloadPath: './'
    });

    // Look for the export button and click it to show the export popup.
    const [button] = await page.$x("//button[contains(., 'Export Rive App')]");
    if (button) {
        await button.click();
    }

    // Look for the export button in the popup.
    const [exportButton] = await page.$x("//button[text()='Export']");
    if (exportButton) {
        await exportButton.click();
    }

    // This starts processing the export.
    console.log('exporting...');

    // Wait for the cancel button to be gone (export completed).
    await page.waitForFunction(function () {
        var buttons = document.getElementsByTagName("button");
        for (var button of buttons) {
            if (button.innerText == 'Cancel') {
                return false;
            }
        }
        return true;
    }, {
        polling: 'mutation'
    });
    console.log('done!');
    
    // Let the download wrap up...
    await page.waitFor(1000)

    await browser.close();
})();