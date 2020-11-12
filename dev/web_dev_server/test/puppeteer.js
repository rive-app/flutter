const puppeteer = require("puppeteer");
const assert = require("assert");

const host = process.env.HOST || "https://zuul-web.rive.app";

const heroWidth = 556;
const pageHeight = 800;
const pageWidth = 1280;
const loginPageWidth = 714;

let browser;
let page;
let username = process.env.USER;
let password = process.env.PASSWORD;

class PageElement {
    constructor({ w, h, ml, mb, mr, mt }) {
        this.width = w;
        this.height = h;
        this.marginLeft = ml;
        this.marginBottom = mb;
        this.marginRight = mr;
        this.marginTop = mt;

        this.click = this.click.bind(this);
        this.centerX = this.centerX.bind(this);
        this.centerY = this.centerY.bind(this);
    }

    centerY() {
        if (this.marginBottom) {
            return pageHeight - this.marginBottom - (this.height / 2);
        }
        else if (this.marginTop) {
            return this.marginTop + (this.height / 2);
        }
    }

    centerX() {
        if (this.marginLeft) {
            return this.marginLeft + (this.width / 2);
        }
        else if (this.marginRight) {
            return pageWidth - this.marginRight - (this.width / 2);
        }
    }

    async click() {
        const x = this.centerX();
        const y = this.centerY();
        assert(x);
        assert(y);

        await page.mouse.click(x, y, { button: 'left' });
    }

    async clickAndWaitNavigation() {
        const element = this;
        await Promise.all([
            page.waitForNavigation({
                waitUntil: "networkidle0"
            }),
            element.click()
        ]);
    }

    async clickAndWaitForTarget(targetRoute) {
        const element = this;
        await Promise.all([
            browser.waitForTarget((target) => {
                const url = target.url();
                const isDone = url.includes(targetRoute);
                console.log("Waiting >>> Done?", isDone, url);
                return isDone;
            }),
            element.click()
        ]);

    }
};

describe("Register & Login Flow", () => {
    function delay(time) {
        return new Promise(function (resolve) {
            setTimeout(resolve, time)
        });
    }

    const options = {
        width: 1280, 
        height: 800 + 131 // 131 is the size of the tab & address bar.
    }

    const loginButton = new PageElement({
        w: 140,
        h: 30,
        ml: heroWidth + 110,
        mb: 138
    });

    const firstField = new PageElement({
        w: 221,
        h: 30,
        ml: loginButton.marginLeft,
        mb: 240
    });

    const secondField = new PageElement({
        w: firstField.width,
        h: firstField.height,
        ml: firstField.marginLeft + firstField.width + 30 /** Padding */,
        mb: firstField.marginBottom
    });

    const thirdField = new PageElement({
        w: firstField.width,
        h: firstField.height,
        ml: firstField.marginLeft,
        mb: firstField.marginBottom - firstField.height - 50
    });

    /** 
        Measurements for this button have been evaluated on macOS and on Ubuntu  
        separately. Unfortunately these appear to differ since Chromium lays out
        Flutter components differently on macOS and Ubuntu.
     */
    let signUpButton;
    if (process.platform === "darwin") {
        signUpButton = new PageElement({
            w: 140,
            h: 30,
            ml: loginButton.marginLeft,
            mb: thirdField.marginBottom - 60
        });
    } else {
        signUpButton = new PageElement({
            w: 140,
            h: 30,
            ml: loginButton.marginLeft,
            mt: 680
        });
    }

    const buttonSwitch = new PageElement({
        w: 40,
        h: 20,
        ml: heroWidth + 544,
        mt: 30
    });

    const recentsButton = new PageElement({
        w: 230,
        h: 31,
        mt: 112,
        ml: 10
    });

    const notificationsButton = new PageElement({
        w: 230,
        h: 31,
        mt: 87,
        ml: 10
    });

    const settingsButton = new PageElement({
        w: 30,
        h: 31,
        mt: 87 + 30 + 47 + 11,
        ml: 190
    });

    const settingsPanelWidth = 881;

    const logoutButton = new PageElement({
        w: 44,
        h: 14,
        mt: 74,
        ml: (pageWidth / 2) + (settingsPanelWidth / 2) - 30 - 44
    });

    // Add unique identifier for the username.
    username += Date.now();
    const email = `${username}@rive.app`


    async function fillTextField({ field, value }) {
        await field.click();
        await page.keyboard.type(value);
    }

    before(async () => {
        browser = await puppeteer.launch({
            // headless: false,
            args: [
                `--window-size=${options.width},${options.height}`
            ]
        });

        const pages = await browser.pages();
        page = pages[0];

        assert(page);

        await page.setViewport({ width: options.width, height: options.height })
        await page.goto(host, { fullPage: true });
        await browser.waitForTarget((target) => target.url().includes("/lobby/register"));

        // const result = await page.evaluate(() => [window.innerWidth, window.innerHeight]);

        /* 
        page.on('request', interceptedRequest => {
            const headers = interceptedRequest.headers();
            const method = interceptedRequest.method();
            const url = interceptedRequest.url();
            console.log("URL:", url);
        });

        await page.on("response", async (response) => {
            const url = response.url();
            const status = response.status();
        });
         */
    });

    it("Register user", async () => {
        assert(password);
        assert(username);
        assert(email);

        const result = await page.evaluate(() => document.location.pathname);
        assert(result.includes("/lobby/register"));

        console.log("Registering user:", username);

        // Wait for page to settle.
        await delay(1500);
        await fillTextField({ field: firstField, value: username });
        await fillTextField({ field: secondField, value: email });
        await fillTextField({ field: thirdField, value: password });

        await signUpButton.click();
        await delay(1000);

        // await page.screenshot({ path: 'screenshot/screenshot_register.png' });

        await signUpButton.clickAndWaitForTarget("/files");
        // await delay(100000);
    });


    it("Log out", async () => {
        const result = await page.evaluate(() => document.location.pathname);
        assert(result.includes("/files"));

        // await page.screenshot({ path: 'screenshot/screenshot_files.png' });

        // Make sure we're on the right page.
        await browser.waitForTarget((target) => target.url().includes("/files"));
        // Delay to let elements layout.
        await delay(1000);
        await settingsButton.click();

        // Delay to let the Settings panel layout.
        await delay(1000);

        // await page.screenshot({ path: 'screenshot/screenshot_settings.png' });

        await logoutButton.clickAndWaitForTarget("/lobby/register");
    });

    it("Log in using credentials", async () => {
        assert(username);
        assert(password);

        await page.goto(`${host}/lobby/login`, { fullPage: true });
        await browser.waitForTarget((target) => target.url().includes("/lobby/login"));

        // Wait for page to settle.
        await delay(1500);

        // await page.screenshot({ path: 'screenshot/screenshot_login.png' });

        // Click username field.
        await firstField.click();
        await page.keyboard.type(username);

        // Click password field.
        await secondField.click();
        await page.keyboard.type(password);

        // Click on Login button & wait for page to load.
        await loginButton.clickAndWaitForTarget("/files");

        // await delay(100000);
    });

    after(async () => {
        await browser.close();
    });
});
